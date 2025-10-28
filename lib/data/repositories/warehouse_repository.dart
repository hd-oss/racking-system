import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/racking_model.dart';

class WarehouseRepository {
  Future<List<Racking>> fetchRacking() async {
    final query = QueryBuilder(ParseObject('Racking'))
      ..setLimit(1000)
      ..orderByAscending("row");
    final response = await query.query();

    if (response.success && (response.results ?? []).isNotEmpty) {
      return (response.results ?? [])
          .map((e) => Racking.fromMap(e.toJson()))
          .toList();
    }
    return [];
  }

  Future<void> updateRack(int row, int col, bool occupied) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Racking'))
      ..whereEqualTo('row', row)
      ..whereEqualTo('col', col);

    final response = await query.query();

    if (!response.success || (response.results ?? []).isEmpty) {
      throw Exception("Rak ($row,$col) tidak ditemukan");
    }

    final rak = response.results!.first as ParseObject;
    rak.set('occupied', occupied);

    final saveResponse = await rak.save();

    if (!saveResponse.success) {
      throw Exception(saveResponse.error?.message ?? "Gagal update rak");
    }
  }

  // Bulk update racking occupied status (optimized untuk import besar)
  Future<Map<String, dynamic>> bulkUpdateRacking(
    List<Map<String, dynamic>> updates,
  ) async {
    final response = await ParseCloudFunction('bulkUpdateRackingOccupied')
        .execute(parameters: {'updates': updates});

    if (response.success) {
      return response.result as Map<String, dynamic>? ?? {};
    } else {
      throw Exception(
        response.error?.message ?? "Gagal bulk update racking",
      );
    }
  }
}
