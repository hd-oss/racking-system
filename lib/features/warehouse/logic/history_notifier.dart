import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/history_model.dart';
import '../../../data/repositories/history_repository.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<History>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return HistoryNotifier(repo);
});

class HistoryNotifier extends StateNotifier<List<History>> {
  final HistoryRepository repository;

  HistoryNotifier(this.repository) : super([]) {
    loadHistory();
  }

  // Always load today's history only
  Future<void> loadHistory() async {
    state = await repository.fetchHistoryToday();
  }

  Future<void> importFromCsv(List<List<dynamic>> rows) async {
    final histories = <History>[];

    for (final row in rows) {
      try {
        if (row.length >= 4) {
          final action = row[0].toString();
          final col = int.parse(row[1].toString());
          final rowValue = int.parse(row[2].toString());
          final timestamp = DateTime.tryParse(row[3].toString()) ?? DateTime.now();

          histories.add(History(
            action: action,
            row: rowValue,
            col: col,
            timestamp: timestamp,
          ));
        }
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    if (histories.isNotEmpty) {
      await repository.saveHistoryBatch(histories);
      await loadHistory(); // refresh list
    }
  }

  // Future<void> add(String action, int row, int col) async {
  //   await repository.saveHistory(History(
  //     action: action,
  //     row: row,
  //     col: col,
  //     timestamp: DateTime.now(),
  //   ));
  //   await loadHistory(); // refresh list setelah insert
  // }
}
