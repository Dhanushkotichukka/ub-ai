class DailyLogModel {
  final String id;
  final String userId;
  final DateTime date;
  final String problemName;
  final String topic;
  final String platform;
  final String difficulty;
  final int timeTaken;
  final String link;
  final String notes;
  final String approach;
  final bool needsRevision;
  final int confidence;
  final bool isBookmarked;
  final bool isFavorite;
  final String source;
  final int xpAwarded;
  final DateTime? createdAt;

  const DailyLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.problemName,
    required this.topic,
    required this.platform,
    required this.difficulty,
    this.timeTaken = 0,
    this.link = '',
    this.notes = '',
    this.approach = '',
    this.needsRevision = false,
    this.confidence = 3,
    this.isBookmarked = false,
    this.isFavorite = false,
    this.source = 'manual',
    this.xpAwarded = 0,
    this.createdAt,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) => DailyLogModel(
    id: json['_id'] ?? '',
    userId: json['userId'] ?? '',
    date: DateTime.parse(json['date']),
    problemName: json['problemName'] ?? '',
    topic: json['topic'] ?? '',
    platform: json['platform'] ?? '',
    difficulty: json['difficulty'] ?? 'medium',
    timeTaken: json['timeTaken'] ?? 0,
    link: json['link'] ?? '',
    notes: json['notes'] ?? '',
    approach: json['approach'] ?? '',
    needsRevision: json['needsRevision'] ?? false,
    confidence: json['confidence'] ?? 3,
    isBookmarked: json['isBookmarked'] ?? false,
    isFavorite: json['isFavorite'] ?? false,
    source: json['source'] ?? 'manual',
    xpAwarded: json['xpAwarded'] ?? 0,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    'problemName': problemName, 'topic': topic, 'platform': platform,
    'difficulty': difficulty, 'timeTaken': timeTaken, 'link': link,
    'notes': notes, 'approach': approach, 'needsRevision': needsRevision,
    'confidence': confidence, 'isBookmarked': isBookmarked, 'isFavorite': isFavorite,
    'date': date.toIso8601String(),
  };
}

class PlatformStatsModel {
  final String id;
  final String platform;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int rating;
  final String rank;
  final int contestCount;
  final int streak;
  final int score;
  final String? profileUrl;
  final String? avatarUrl;
  final DateTime? lastSynced;

  const PlatformStatsModel({
    required this.id,
    required this.platform,
    this.totalSolved = 0,
    this.easySolved = 0,
    this.mediumSolved = 0,
    this.hardSolved = 0,
    this.rating = 0,
    this.rank = '',
    this.contestCount = 0,
    this.streak = 0,
    this.score = 0,
    this.profileUrl,
    this.avatarUrl,
    this.lastSynced,
  });

  factory PlatformStatsModel.fromJson(Map<String, dynamic> json) => PlatformStatsModel(
    id: json['_id'] ?? '',
    platform: json['platform'] ?? '',
    totalSolved: json['totalSolved'] ?? 0,
    easySolved: json['easySolved'] ?? 0,
    mediumSolved: json['mediumSolved'] ?? 0,
    hardSolved: json['hardSolved'] ?? 0,
    rating: json['rating'] ?? 0,
    rank: json['rank'] ?? '',
    contestCount: json['contestCount'] ?? 0,
    streak: json['streak'] ?? 0,
    score: json['score'] ?? 0,
    profileUrl: json['profileUrl'],
    avatarUrl: json['avatarUrl'],
    lastSynced: json['lastSynced'] != null ? DateTime.parse(json['lastSynced']) : null,
  );
}

class TopicModel {
  final String id;
  final String topic;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int totalSolved;
  final int target;
  final int mastery;
  final String status;
  final DateTime? lastPracticed;

  const TopicModel({
    required this.id,
    required this.topic,
    this.easySolved = 0,
    this.mediumSolved = 0,
    this.hardSolved = 0,
    this.totalSolved = 0,
    this.target = 30,
    this.mastery = 0,
    this.status = 'not_started',
    this.lastPracticed,
  });

  double get progress => target > 0 ? (totalSolved / target).clamp(0.0, 1.0) : 0;

  factory TopicModel.fromJson(Map<String, dynamic> json) => TopicModel(
    id: json['_id'] ?? '',
    topic: json['topic'] ?? '',
    easySolved: json['easySolved'] ?? 0,
    mediumSolved: json['mediumSolved'] ?? 0,
    hardSolved: json['hardSolved'] ?? 0,
    totalSolved: json['totalSolved'] ?? 0,
    target: json['target'] ?? 30,
    mastery: json['mastery'] ?? 0,
    status: json['status'] ?? 'not_started',
    lastPracticed: json['lastPracticed'] != null ? DateTime.parse(json['lastPracticed']) : null,
  );
}

class PotdModel {
  final String platform;
  final String title;
  final String difficulty;
  final String link;
  final String? date;
  final List<String> tags;

  const PotdModel({
    required this.platform,
    required this.title,
    required this.difficulty,
    required this.link,
    this.date,
    this.tags = const [],
  });

  factory PotdModel.fromJson(Map<String, dynamic> json) => PotdModel(
    platform: json['platform'] ?? '',
    title: json['title'] ?? '',
    difficulty: json['difficulty'] ?? 'medium',
    link: json['link'] ?? '',
    date: json['date'],
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class ContestModel {
  final String id;
  final String platform;
  final String name;
  final DateTime startTime;
  final int durationSeconds;
  final String registerUrl;
  final String? type;

  const ContestModel({
    required this.id,
    required this.platform,
    required this.name,
    required this.startTime,
    required this.durationSeconds,
    required this.registerUrl,
    this.type,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) => ContestModel(
    id: json['id'] ?? '',
    platform: json['platform'] ?? '',
    name: json['name'] ?? '',
    startTime: DateTime.parse(json['startTime']),
    durationSeconds: json['durationSeconds'] ?? 7200,
    registerUrl: json['registerUrl'] ?? '',
    type: json['type'],
  );

  Duration get timeUntilStart => startTime.difference(DateTime.now());
  bool get isUpcoming => startTime.isAfter(DateTime.now());
}

class TodoTask {
  final String id;
  final String text;
  final String type;
  final String platform;
  final String link;
  final bool isCompleted;
  final String priority;
  final int estimatedMinutes;

  const TodoTask({
    required this.id,
    required this.text,
    this.type = 'problem',
    this.platform = '',
    this.link = '',
    this.isCompleted = false,
    this.priority = 'medium',
    this.estimatedMinutes = 30,
  });

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    type: json['type'] ?? 'problem',
    platform: json['platform'] ?? '',
    link: json['link'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    priority: json['priority'] ?? 'medium',
    estimatedMinutes: json['estimatedMinutes'] ?? 30,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'type': type, 'platform': platform,
    'link': link, 'isCompleted': isCompleted, 'priority': priority,
    'estimatedMinutes': estimatedMinutes,
  };

  TodoTask copyWith({bool? isCompleted, String? text, String? priority}) => TodoTask(
    id: id, text: text ?? this.text, type: type, platform: platform, link: link,
    isCompleted: isCompleted ?? this.isCompleted, priority: priority ?? this.priority,
    estimatedMinutes: estimatedMinutes,
  );
}

class TodoPlanModel {
  final String id;
  final DateTime date;
  final String title;
  final List<TodoTask> tasks;
  final bool isAutoGenerated;

  const TodoPlanModel({
    required this.id,
    required this.date,
    this.title = "Today's Plan",
    this.tasks = const [],
    this.isAutoGenerated = false,
  });

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  factory TodoPlanModel.fromJson(Map<String, dynamic> json) => TodoPlanModel(
    id: json['_id'] ?? '',
    date: DateTime.parse(json['date']),
    title: json['title'] ?? "Today's Plan",
    tasks: (json['tasks'] as List? ?? []).map((t) => TodoTask.fromJson(t)).toList(),
    isAutoGenerated: json['isAutoGenerated'] ?? false,
  );
}
