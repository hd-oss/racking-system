import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/history_model.dart';

class HistoryRepository {
  Future<List<History>> fetchHistory() async {
    final query = QueryBuilder<ParseObject>(ParseObject('History'))
      ..orderByDescending('timestamp');

    final response = await query.query();

    if (response.success && response.results != null) {
      return (response.results ?? []).map((e) {
        final obj = e as ParseObject;
        return History(
            action: obj.get<String>('action') ?? '',
            row: obj.get<int>('row') ?? 0,
            col: obj.get<int>('col') ?? 0,
            timestamp: obj.get<DateTime>('timestamp') ?? DateTime.now());
      }).toList();
    }

    return [];
  }

  Future<List<History>> fetchHistoryToday() async {
    try {
      // Call server-side Cloud Function to get today's history with UTC filtering
      final response = await ParseCloudFunction('getTodayHistory').execute();

      if (response.success) {
        final result = response.result as Map<String, dynamic>? ?? {};
        final dataList = result['data'] as List? ?? [];

        return dataList.map((item) {
          final map = item as Map<String, dynamic>;
          final timestamp = _parseTimestamp(map['timestamp']);
          return History(
            action: map['action']?.toString() ?? '',
            row: (map['row'] as num?)?.toInt() ?? 0,
            col: (map['col'] as num?)?.toInt() ?? 0,
            timestamp: timestamp,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching today history: $e');
      return [];
    }
  }

  /// Parse timestamp from Parse Cloud Function response
  /// Handles both ISO string format and Parse Date object format
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    // Handle string ISO format
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return DateTime.now();
      }
    }

    // Handle Parse Date object format: {__type: Date, iso: "2025-10-28T02:55:20.125Z"}
    if (timestamp is Map<String, dynamic>) {
      final iso = timestamp['iso'];
      if (iso is String) {
        try {
          return DateTime.parse(iso);
        } catch (e) {
          print('Error parsing ISO timestamp: $e');
          return DateTime.now();
        }
      }
    }

    return DateTime.now();
  }

  Future<void> saveHistory(History history) async {
    final parseObject = ParseObject('History')
      ..set('action', history.action)
      ..set('row', history.row)
      ..set('col', history.col)
      ..set('timestamp', history.timestamp);

    await parseObject.save();
  }

  Future<void> saveHistoryBatch(List<History> histories) async {
    for (final history in histories) {
      await saveHistory(history);
    }
  }
}
