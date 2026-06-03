class HiveKeys {
  static const userBox = 'user_box';
  static const settingsBox = 'settings_box';
  static const cacheBox = 'cache_box';

  // Keys within boxes
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const userJson = 'user_json';
  static const darkMode = 'dark_mode';
  static const lastSync = 'last_sync';
}

class AppConstants {
  // Base URL — change to your deployed backend URL
  static const baseUrl = 'https://ub-ai.onrender.com/api/v1'; // Production Render API

  static const appName = 'UB AI';
  static const appTagline = 'Track • Practice • Learn • Plan • Crack Placements';

  static const List<String> topics = [
    'Arrays', 'Strings', 'Linked List', 'Stack', 'Queue',
    'Trees', 'Binary Trees', 'Binary Search Trees', 'Graphs',
    'Dynamic Programming', 'Greedy', 'Backtracking',
    'Binary Search', 'Two Pointers', 'Sliding Window',
    'Hashing', 'Heap/Priority Queue', 'Tries',
    'Segment Trees', 'Fenwick Trees', 'Math',
    'Bit Manipulation', 'Recursion', 'Divide and Conquer',
    'Design', 'Other',
  ];

  static const List<String> platforms = [
    'LeetCode', 'GFG', 'Codeforces', 'CodeChef', 'HackerRank', 'AtCoder', 'Other',
  ];

  static const List<String> difficulties = ['easy', 'medium', 'hard'];

  static const List<String> branches = ['CSE', 'IT', 'AIML', 'ECE', 'EEE', 'MECH', 'CIVIL', 'OTHER'];

  static const List<String> languages = ['Java', 'Python', 'C++', 'JavaScript', 'C', 'Go', 'Rust'];

  static const List<String> dreamCompanies = [
    'Google', 'Amazon', 'Microsoft', 'Meta', 'Apple',
    'Adobe', 'Flipkart', 'Uber', 'Netflix', 'Other',
  ];

  static const Map<String, int> xpValues = {
    'easy_solved': 10,
    'medium_solved': 25,
    'hard_solved': 50,
    'daily_goal_completed': 30,
    'contest_participated': 40,
    'revision_completed': 15,
    'streak_7': 100,
    'streak_30': 500,
  };

  static const List<String> levelNames = [
    'Beginner', 'Novice', 'Learner', 'Apprentice', 'Intermediate',
    'Skilled', 'Proficient', 'Advanced', 'Expert', 'Master', 'Champion', 'Legend',
  ];

  static const List<int> levelThresholds = [
    0, 200, 500, 1000, 2000, 3500, 5500, 8000, 12000, 18000, 25000, 35000,
  ];
}
