import '../../../shared/services/api_service.dart';
import '../../../shared/models/models.dart';

class HomeRepository {
  final ApiService _api;
  HomeRepository(this._api);

  Future<List<PlatformStatsModel>> getPlatformStats() async {
    final res = await _api.get('/platforms/stats');
    return (res.data['stats'] as List).map((s) => PlatformStatsModel.fromJson(s)).toList();
  }

  Future<Map<String, PotdModel?>> getPOTD() async {
    final res = await _api.get('/platforms/potd');
    final potd = res.data['potd'];
    return {
      'leetcode': potd['leetcode'] != null ? PotdModel.fromJson(potd['leetcode']) : null,
      'gfg': potd['gfg'] != null ? PotdModel.fromJson(potd['gfg']) : null,
    };
  }

  Future<List<PlatformStatsModel>> syncPlatforms() async {
    final res = await _api.post('/platforms/sync');
    return (res.data['stats'] as List).map((s) => PlatformStatsModel.fromJson(s)).toList();
  }

  Future<List<ContestModel>> getUpcomingContests() async {
    final res = await _api.get('/contests/upcoming');
    return (res.data['contests'] as List).map((c) => ContestModel.fromJson(c)).toList();
  }

  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    final res = await _api.get('/analytics/overview');
    return res.data['overview'];
  }

  Future<List<Map<String, dynamic>>> getHeatmap({int? year}) async {
    final res = await _api.get('/analytics/heatmap', params: {'year': year ?? DateTime.now().year});
    return List<Map<String, dynamic>>.from(res.data['heatmap']);
  }
}
