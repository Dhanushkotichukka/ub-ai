import '../../../shared/services/api_service.dart';

class RevisionRepository {
  final ApiService _api;

  RevisionRepository(this._api);

  Future<List<Map<String, dynamic>>> getDueRevisions() async {
    final res = await _api.get('/revision/due');
    return List<Map<String, dynamic>>.from(res.data['revisions']);
  }

  Future<List<Map<String, dynamic>>> getSchedule() async {
    final res = await _api.get('/revision/schedule');
    return List<Map<String, dynamic>>.from(res.data['schedule']);
  }

  Future<void> markRevised(String id, int confidence) async {
    await _api.post('/revision/mark/$id', data: {'confidence': confidence});
  }
}
