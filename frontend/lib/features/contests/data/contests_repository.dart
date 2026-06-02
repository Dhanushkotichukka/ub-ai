import '../../../shared/services/api_service.dart';
import '../../../shared/models/models.dart';

class ContestsRepository {
  final ApiService _api;

  ContestsRepository(this._api);

  Future<List<ContestModel>> getUpcomingContests() async {
    final res = await _api.get('/contests/upcoming');
    return (res.data['contests'] as List)
        .map((c) => ContestModel.fromJson(c))
        .toList();
  }
}
