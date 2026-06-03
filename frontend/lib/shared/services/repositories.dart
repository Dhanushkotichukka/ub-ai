import '../../../shared/services/api_service.dart';
import '../../../shared/models/models.dart';

class TrackerRepository {
  final ApiService _api;
  TrackerRepository(this._api);

  Future<List<DailyLogModel>> getLogs({String? date, String? topic, String? platform, int limit = 50}) async {
    final res = await _api.get('/logs', params: {if (date != null) 'date': date, if (topic != null) 'topic': topic, if (platform != null) 'platform': platform, 'limit': limit});
    return (res.data['logs'] as List).map((l) => DailyLogModel.fromJson(l)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get('/logs/stats/overview');
    return res.data['stats'];
  }

  Future<DailyLogModel> addLog(Map<String, dynamic> data) async {
    final res = await _api.post('/logs', data: data);
    return DailyLogModel.fromJson(res.data['log']);
  }

  Future<DailyLogModel> updateLog(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/logs/$id', data: data);
    return DailyLogModel.fromJson(res.data['log']);
  }

  Future<void> deleteLog(String id) => _api.delete('/logs/$id');
}

class TopicRepository {
  final ApiService _api;
  TopicRepository(this._api);

  Future<List<TopicModel>> getTopics() async {
    final res = await _api.get('/topics');
    return (res.data['topics'] as List).map((t) => TopicModel.fromJson(t)).toList();
  }

  Future<Map<String, dynamic>> getTopicDetail(String topic) async {
    final res = await _api.get('/topics/$topic');
    return {'topic': TopicModel.fromJson(res.data['topic']), 'recentProblems': res.data['recentProblems']};
  }

  Future<List<TopicModel>> recalculate() async {
    final res = await _api.post('/topics/recalculate');
    return (res.data['topics'] as List).map((t) => TopicModel.fromJson(t)).toList();
  }
}

class PlanRepository {
  final ApiService _api;
  PlanRepository(this._api);

  Future<TodoPlanModel?> getPlan({String? date}) async {
    final res = await _api.get('/plan', params: {if (date != null) 'date': date});
    if (res.data['plan'] == null) return null;
    return TodoPlanModel.fromJson(res.data['plan']);
  }

  Future<TodoPlanModel> addTask(Map<String, dynamic> task, {String? date}) async {
    final res = await _api.post('/plan/task', data: {'task': task, if (date != null) 'date': date});
    return TodoPlanModel.fromJson(res.data['plan']);
  }

  Future<TodoPlanModel> updateTask(String taskId, {required bool isCompleted, String? date}) async {
    final res = await _api.put('/plan/task/$taskId', data: {'isCompleted': isCompleted, if (date != null) 'date': date});
    return TodoPlanModel.fromJson(res.data['plan']);
  }

  Future<TodoPlanModel> deleteTask(String taskId, {String? date}) async {
    final res = await _api.delete('/plan/task/$taskId');
    return TodoPlanModel.fromJson(res.data['plan']);
  }

  Future<TodoPlanModel> autoGenerate({String? date}) async {
    final res = await _api.post('/plan/auto-generate', data: {if (date != null) 'date': date});
    return TodoPlanModel.fromJson(res.data['plan']);
  }
}

class NotesRepository {
  final ApiService _api;
  NotesRepository(this._api);

  Future<List<Map<String, dynamic>>> getNotes({String? folder, String? search, String? type, String? collection, bool? dueReview}) async {
    final res = await _api.get('/notes', params: {
      if (folder != null) 'folder': folder,
      if (search != null) 'search': search,
      if (type != null) 'type': type,
      if (collection != null) 'collection': collection,
      if (dueReview == true) 'dueReview': 'true',
    });
    return List<Map<String, dynamic>>.from(res.data['notes']);
  }

  Future<Map<String, dynamic>> getNote(String id) async {
    final res = await _api.get('/notes/$id');
    return res.data['note'];
  }

  Future<Map<String, dynamic>> getDailyNote() async {
    final res = await _api.get('/notes/daily');
    return res.data['note'];
  }

  Future<List<Map<String, dynamic>>> getRevisionNotes() async {
    final res = await _api.get('/notes/revision');
    return List<Map<String, dynamic>>.from(res.data['notes']);
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get('/notes/stats');
    return res.data['stats'];
  }

  Future<Map<String, dynamic>> createNote(Map<String, dynamic> data) async {
    final res = await _api.post('/notes', data: data);
    return res.data['note'];
  }

  Future<Map<String, dynamic>> updateNote(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/notes/$id', data: data);
    return res.data['note'];
  }

  Future<void> deleteNote(String id) => _api.delete('/notes/$id');

  Future<List<Map<String, dynamic>>> getFolders() async {
    final res = await _api.get('/notes/folders');
    return List<Map<String, dynamic>>.from(res.data['folders']);
  }

  // ─── AI Features ──────────────────────────────────────────────
  Future<String> aiChat(String noteId, String message) async {
    final res = await _api.post('/notes/$noteId/ai-chat', data: {'message': message});
    return res.data['reply'];
  }

  Future<Map<String, dynamic>> autoTag(String noteId) async {
    final res = await _api.post('/notes/$noteId/auto-tag');
    return {'title': res.data['title'], 'tags': res.data['tags']};
  }

  Future<String> generateSummary(String noteId) async {
    final res = await _api.post('/notes/$noteId/summary');
    return res.data['aiSummary'];
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String noteId, {int count = 5}) async {
    final res = await _api.post('/notes/$noteId/quiz', data: {'questionCount': count});
    return List<Map<String, dynamic>>.from(res.data['quiz']);
  }

  Future<String> generateRoadmap(String noteId) async {
    final res = await _api.post('/notes/$noteId/roadmap');
    return res.data['roadmap'];
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String noteId, {int count = 7}) async {
    final res = await _api.post('/notes/$noteId/flashcards', data: {'count': count});
    return List<Map<String, dynamic>>.from(res.data['flashcards']);
  }

  Future<Map<String, dynamic>> scheduleRevision(String noteId) async {
    final res = await _api.post('/notes/$noteId/revision-schedule');
    return res.data;
  }

  Future<List<Map<String, dynamic>>> semanticSearch(String query) async {
    final res = await _api.post('/notes/semantic-search', data: {'query': query});
    return List<Map<String, dynamic>>.from(res.data['notes']);
  }
}

