

import '../../data/repositories/warehouse_repository.dart';

/// Use case for bulk updating racking status with efficient database operation
class BulkUpdateRackingUseCase {
  final WarehouseRepository repository;

  BulkUpdateRackingUseCase(this.repository);

  /// Bulk update racking status with single API call
  ///
  /// Parameters:
  /// - updates: List of {row, col, occupied} maps
  ///
  /// Returns map with operation results
  Future<Map<String, dynamic>> call(List<Map<String, dynamic>> updates) async {
    return await repository.bulkUpdateRacking(updates);
  }
}
