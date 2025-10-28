

import 'package:app_gudang/data/repositories/warehouse_repository.dart';

/// Use case for updating racking occupied status
class UpdateRackingUseCase {
  final WarehouseRepository repository;

  UpdateRackingUseCase(this.repository);

  /// Update single racking status
  ///
  /// Throws exception if racking not found or not active
  Future<void> call(int row, int col, bool occupied) async {
    await repository.updateRack(row, col, occupied);
  }
}
