import '../../../shared/services/api_service.dart';

class AnalyticsRepository {
  final ApiService _api;

  AnalyticsRepository(this._api);

  Future<Map<String, dynamic>> fetchOverview() async {
    final res = await _api.get('/analytics/overview');
    return res.data['overview'];
  }

  // Not used in screen right now, but good to have based on routes
  Future<List<dynamic>> fetchTopics() async {
    final res = await _api.get('/analytics/topics');
    return res.data['topics'] ?? [];
  }

  Future<List<dynamic>> fetchWeekly() async {
    final res = await _api.get('/analytics/weekly');
    return res.data['weeklyData'] ?? [];
  }

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final res = await _api.get('/reports');
    return List<Map<String, dynamic>>.from(res.data['reports'] ?? []);
  }

  Future<Map<String, dynamic>> generateReport() async {
    final res = await _api.post('/reports/generate');
    return res.data['report'] as Map<String, dynamic>;
  }
}
