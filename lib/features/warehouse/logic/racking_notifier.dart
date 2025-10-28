import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/racking_model.dart';
import '../../../data/repositories/warehouse_repository.dart';

final warehouseRepositoryProvider = Provider((ref) => WarehouseRepository());

final rackingProvider =
    StateNotifierProvider<RackingNotifier, List<Racking>>((ref) {
  final repo = ref.watch(warehouseRepositoryProvider);
  return RackingNotifier(repo);
});

class RackingNotifier extends StateNotifier<List<Racking>> {
  final WarehouseRepository repository;

  RackingNotifier(this.repository) : super([]) {
    loadRacking();
  }

  Future<void> loadRacking() async {
    state = await repository.fetchRacking();
  }

  Future<void> setOccupied(
    int row,
    int col,
    bool occupied,
  ) async {
    await repository.updateRack(row, col, occupied);
    state = [
      for (final rack in state)
        if (rack.row == row && rack.col == col)
          Racking(
            row: row,
            col: col,
            occupied: occupied,
          )
        else
          rack
    ];
  }

  // Import racking data from Excel (bulk operation optimized)
  // Format: [rak, level, occupied_value]
  // occupied_value can be: true/false, 1/0, "IN"/"OUT", "true"/"false"
  Future<void> importRackingData(List<List<dynamic>> rows) async {
    final updates = <Map<String, dynamic>>[];

    // Parse semua rows terlebih dahulu
    for (final row in rows) {
      try {
        if (row.length >= 3) {
          final rak = int.parse(row[0].toString());
          final level = int.parse(row[1].toString());
          final occupiedValue = row[2];

          // Parse occupied status
          bool occupied = false;
          if (occupiedValue is bool) {
            occupied = occupiedValue;
          } else if (occupiedValue is int) {
            occupied = occupiedValue != 0;
          } else {
            final str = occupiedValue.toString().toLowerCase();
            occupied = str == 'true' || str == '1' || str == 'in';
          }

          // Tambah ke updates array (row untuk putaran, level untuk kolom)
          updates.add({
            'row': level,
            'col': rak,
            'occupied': occupied,
          });
        }
      } catch (e) {
        // Skip invalid rows
        // Silently skip invalid rows during parsing
        continue;
      }
    }

    // Bulk update semua sekaligus (1 API call)
    if (updates.isNotEmpty) {
      try {
        final result = await repository.bulkUpdateRacking(updates);

        // Update state dengan hasil dari server
        if (result['details'] != null) {
          final successList = result['details']['success'] as List? ?? [];

          // Update state untuk items yang berhasil
          for (final item in successList) {
            final row = item['row'] as int;
            final col = item['col'] as int;
            final occupied = item['occupied'] as bool;

            state = [
              for (final rack in state)
                if (rack.row == row && rack.col == col)
                  Racking(
                    row: row,
                    col: col,
                    occupied: occupied,
                  )
                else
                  rack
            ];
          }
        }
      } catch (e) {
        // Propagate error untuk ditangani di UI
        rethrow;
      }
    }
  }
}
