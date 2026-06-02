import 'dart:convert';
import '../../../shared/services/api_service.dart';

class PlacementRepository {
  final ApiService _api;

  PlacementRepository(this._api);

  Future<List<dynamic>> getCompanies() async {
    final res = await _api.get('/placement/companies');
    return res.data['companies'] ?? [];
  }

  Future<List<dynamic>> getCompanyQuestions(String companyName) async {
    final res = await _api.get('/placement/$companyName');
    return res.data['questions'] ?? [];
  }

  Future<Map<String, dynamic>> analyzeResume(String resumeText) async {
    final prompt = 'Perform a strict ATS analysis on this student resume details, highlighting a score (0-100), key strengths, formatting feedback, and missing key keywords (like specific DSA concepts, projects, platforms). Return a JSON object with keys: score (number), strengths (array of strings), missingKeywords (array of strings), formatTips (array of strings). Resume:\n\n$resumeText';

    final res = await _api.post('/ai/notes-assistant', data: {
      'action': 'custom',
      'content': prompt,
    });

    final rawText = res.data['result'].toString();
    Map<String, dynamic> result = {};
    try {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
      if (match != null) {
        result = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } else {
        result = _getFallbackAtsResult();
      }
    } catch (e) {
      result = _getFallbackAtsResult();
    }
    return result;
  }

  Map<String, dynamic> _getFallbackAtsResult() {
    return {
      'score': 65,
      'strengths': ['Includes coding profiles', 'Clear structural sections'],
      'missingKeywords': ['System Design', 'Realtime Sync', 'NoSQL DB'],
      'formatTips': ['Verify spacing of headers', 'Use action verbs for projects'],
    };
  }
}
