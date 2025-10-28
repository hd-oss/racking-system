
import '../../data/models/history_model.dart';
import '../../data/repositories/history_repository.dart';

/// Use case for fetching history data
class GetHistoryUseCase {
  final HistoryRepository repository;

  GetHistoryUseCase(this.repository);

  /// Get all history from database
  Future<List<History>> getAll() async {
    return await repository.fetchHistory();
  }

  /// Get today's history only
  /// Uses WIB (UTC+7) timezone calculation
  Future<List<History>> getToday() async {
    return await repository.fetchHistoryToday();
  }
}
