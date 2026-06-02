import '../../../shared/services/api_service.dart';

class AiCoachRepository {
  final ApiService _api;

  AiCoachRepository(this._api);

  Future<List<Map<String, dynamic>>> fetchChatHistory() async {
    final res = await _api.get('/ai/chat');
    return List<Map<String, dynamic>>.from(res.data['messages'] ?? []);
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final res = await _api.post('/ai/chat', data: {'message': message});
    return {
      'role': 'assistant',
      'content': res.data['reply'],
      'timestamp': res.data['timestamp'],
    };
  }
}
