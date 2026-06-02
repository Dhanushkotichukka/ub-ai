class UserModel {
  final String id;
  final String email;
  final String name;
  final String profilePic;
  final String? googleId;
  final bool isEmailVerified;
  final String rollNumber;
  final String branch;
  final int? year;
  final String phone;
  final String college;
  final int? graduationYear;
  final String dreamCompany;
  final double? cgpa;
  final String preferredLanguage;
  final String appPurpose;
  final PlatformHandles platforms;
  final int xp;
  final int level;
  final int streak;
  final int longestStreak;
  final List<String> badges;
  final bool onboardingComplete;
  final int onboardingStep;
  final UserSettings settings;
  final DateTime? createdAt;
  final DateTime? lastActiveDate;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profilePic = '',
    this.googleId,
    this.isEmailVerified = false,
    this.rollNumber = '',
    this.branch = '',
    this.year,
    this.phone = '',
    this.college = '',
    this.graduationYear,
    this.dreamCompany = '',
    this.cgpa,
    this.preferredLanguage = '',
    this.appPurpose = '',
    this.platforms = const PlatformHandles(),
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    this.onboardingComplete = false,
    this.onboardingStep = 0,
    this.settings = const UserSettings(),
    this.createdAt,
    this.lastActiveDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? '',
      googleId: json['googleId'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      rollNumber: json['rollNumber'] ?? '',
      branch: json['branch'] ?? '',
      year: json['year'],
      phone: json['phone'] ?? '',
      college: json['college'] ?? '',
      graduationYear: json['graduationYear'],
      dreamCompany: json['dreamCompany'] ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      preferredLanguage: json['preferredLanguage'] ?? '',
      appPurpose: json['appPurpose'] ?? '',
      platforms: json['platforms'] != null
          ? PlatformHandles.fromJson(json['platforms'])
          : const PlatformHandles(),
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      onboardingComplete: json['onboardingComplete'] ?? false,
      onboardingStep: json['onboardingStep'] ?? 0,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'])
          : const UserSettings(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastActiveDate: json['lastActiveDate'] != null ? DateTime.parse(json['lastActiveDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id, 'email': email, 'name': name, 'profilePic': profilePic,
    'rollNumber': rollNumber, 'branch': branch, 'year': year, 'phone': phone,
    'college': college, 'graduationYear': graduationYear, 'dreamCompany': dreamCompany,
    'cgpa': cgpa, 'preferredLanguage': preferredLanguage, 'appPurpose': appPurpose,
    'platforms': platforms.toJson(), 'xp': xp, 'level': level, 'streak': streak,
    'badges': badges, 'onboardingComplete': onboardingComplete, 'settings': settings.toJson(),
  };

  UserModel copyWith({
    String? name, String? profilePic, String? rollNumber, String? branch,
    int? year, String? phone, String? college, int? graduationYear,
    String? dreamCompany, double? cgpa, String? preferredLanguage, String? appPurpose,
    PlatformHandles? platforms, int? xp, int? level, int? streak,
    bool? onboardingComplete, int? onboardingStep, UserSettings? settings,
    List<String>? badges,
  }) => UserModel(
    id: id, email: email, googleId: googleId, isEmailVerified: isEmailVerified,
    name: name ?? this.name,
    profilePic: profilePic ?? this.profilePic,
    rollNumber: rollNumber ?? this.rollNumber,
    branch: branch ?? this.branch,
    year: year ?? this.year,
    phone: phone ?? this.phone,
    college: college ?? this.college,
    graduationYear: graduationYear ?? this.graduationYear,
    dreamCompany: dreamCompany ?? this.dreamCompany,
    cgpa: cgpa ?? this.cgpa,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    appPurpose: appPurpose ?? this.appPurpose,
    platforms: platforms ?? this.platforms,
    xp: xp ?? this.xp,
    level: level ?? this.level,
    streak: streak ?? this.streak,
    longestStreak: longestStreak,
    badges: badges ?? this.badges,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    onboardingStep: onboardingStep ?? this.onboardingStep,
    settings: settings ?? this.settings,
    createdAt: createdAt,
    lastActiveDate: lastActiveDate,
  );
}

class PlatformHandles {
  final String leetcode;
  final String gfg;
  final String codeforces;
  final String codechef;
  final String hackerrank;
  final String github;

  const PlatformHandles({
    this.leetcode = '', this.gfg = '', this.codeforces = '',
    this.codechef = '', this.hackerrank = '', this.github = '',
  });

  factory PlatformHandles.fromJson(Map<String, dynamic> json) => PlatformHandles(
    leetcode: json['leetcode'] ?? '',
    gfg: json['gfg'] ?? '',
    codeforces: json['codeforces'] ?? '',
    codechef: json['codechef'] ?? '',
    hackerrank: json['hackerrank'] ?? '',
    github: json['github'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'leetcode': leetcode, 'gfg': gfg, 'codeforces': codeforces,
    'codechef': codechef, 'hackerrank': hackerrank, 'github': github,
  };
}

class UserSettings {
  final bool darkMode;
  final String accentColor;
  final String fontSize;
  final NotificationSettings notifications;
  final Map<String, bool> platformVisibility;
  final List<String> platformOrder;

  const UserSettings({
    this.darkMode = true,
    this.accentColor = '#6C63FF',
    this.fontSize = 'medium',
    this.notifications = const NotificationSettings(),
    this.platformVisibility = const {
      'leetcode': true, 'gfg': true, 'codeforces': true,
      'codechef': true, 'hackerrank': false, 'github': true,
    },
    this.platformOrder = const ['leetcode', 'gfg', 'codeforces', 'codechef', 'hackerrank', 'github'],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    darkMode: json['darkMode'] ?? true,
    accentColor: json['accentColor'] ?? '#6C63FF',
    fontSize: json['fontSize'] ?? 'medium',
    notifications: json['notifications'] != null
        ? NotificationSettings.fromJson(json['notifications'])
        : const NotificationSettings(),
    platformVisibility: json['platformVisibility'] != null
        ? Map<String, bool>.from(json['platformVisibility'])
        : const {'leetcode': true, 'gfg': true, 'codeforces': true, 'codechef': true, 'hackerrank': false, 'github': true},
    platformOrder: json['platformOrder'] != null
        ? List<String>.from(json['platformOrder'])
        : const ['leetcode', 'gfg', 'codeforces', 'codechef', 'hackerrank', 'github'],
  );

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode, 'accentColor': accentColor, 'fontSize': fontSize,
    'notifications': notifications.toJson(),
    'platformVisibility': platformVisibility, 'platformOrder': platformOrder,
  };

  UserSettings copyWith({bool? darkMode, String? accentColor, String? fontSize,
    NotificationSettings? notifications, Map<String, bool>? platformVisibility, List<String>? platformOrder}) =>
    UserSettings(
      darkMode: darkMode ?? this.darkMode,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      notifications: notifications ?? this.notifications,
      platformVisibility: platformVisibility ?? this.platformVisibility,
      platformOrder: platformOrder ?? this.platformOrder,
    );
}

class NotificationSettings {
  final bool dailyReminder;
  final String dailyReminderTime;
  final bool contestReminders;
  final bool revisionReminders;
  final bool streakWarnings;

  const NotificationSettings({
    this.dailyReminder = true,
    this.dailyReminderTime = '19:00',
    this.contestReminders = true,
    this.revisionReminders = true,
    this.streakWarnings = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => NotificationSettings(
    dailyReminder: json['dailyReminder'] ?? true,
    dailyReminderTime: json['dailyReminderTime'] ?? '19:00',
    contestReminders: json['contestReminders'] ?? true,
    revisionReminders: json['revisionReminders'] ?? true,
    streakWarnings: json['streakWarnings'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'dailyReminder': dailyReminder, 'dailyReminderTime': dailyReminderTime,
    'contestReminders': contestReminders, 'revisionReminders': revisionReminders,
    'streakWarnings': streakWarnings,
  };
}
