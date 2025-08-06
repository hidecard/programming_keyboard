import 'achievement.dart';

class Statistics {
  final int totalLessonsCompleted;
  final int totalPracticeTime; // in minutes
  final double averageWpm;
  final double bestWpm;
  final double averageAccuracy;
  final double bestAccuracy;
  final int totalCharactersTyped;
  final int totalErrors;
  final int currentStreak;
  final int longestStreak;
  final int perfectLessons;
  final DateTime lastPracticeDate;
  final Map<String, int> lessonsByLanguage;
  final List<PracticeSession> recentSessions;

  Statistics({
    required this.totalLessonsCompleted,
    required this.totalPracticeTime,
    required this.averageWpm,
    required this.bestWpm,
    required this.averageAccuracy,
    required this.bestAccuracy,
    required this.totalCharactersTyped,
    required this.totalErrors,
    required this.currentStreak,
    required this.longestStreak,
    required this.perfectLessons,
    required this.lastPracticeDate,
    required this.lessonsByLanguage,
    required this.recentSessions,
  });

  Statistics copyWith({
    int? totalLessonsCompleted,
    int? totalPracticeTime,
    double? averageWpm,
    double? bestWpm,
    double? averageAccuracy,
    double? bestAccuracy,
    int? totalCharactersTyped,
    int? totalErrors,
    int? currentStreak,
    int? longestStreak,
    int? perfectLessons,
    DateTime? lastPracticeDate,
    Map<String, int>? lessonsByLanguage,
    List<PracticeSession>? recentSessions,
  }) {
    return Statistics(
      totalLessonsCompleted:
          totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalPracticeTime: totalPracticeTime ?? this.totalPracticeTime,
      averageWpm: averageWpm ?? this.averageWpm,
      bestWpm: bestWpm ?? this.bestWpm,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      totalCharactersTyped: totalCharactersTyped ?? this.totalCharactersTyped,
      totalErrors: totalErrors ?? this.totalErrors,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      perfectLessons: perfectLessons ?? this.perfectLessons,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      lessonsByLanguage: lessonsByLanguage ?? this.lessonsByLanguage,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalPracticeTime': totalPracticeTime,
      'averageWpm': averageWpm,
      'bestWpm': bestWpm,
      'averageAccuracy': averageAccuracy,
      'bestAccuracy': bestAccuracy,
      'totalCharactersTyped': totalCharactersTyped,
      'totalErrors': totalErrors,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'perfectLessons': perfectLessons,
      'lastPracticeDate': lastPracticeDate.toIso8601String(),
      'lessonsByLanguage': lessonsByLanguage,
      'recentSessions': recentSessions
          .map((session) => session.toJson())
          .toList(),
    };
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalPracticeTime: json['totalPracticeTime'] ?? 0,
      averageWpm: json['averageWpm']?.toDouble() ?? 0.0,
      bestWpm: json['bestWpm']?.toDouble() ?? 0.0,
      averageAccuracy: json['averageAccuracy']?.toDouble() ?? 0.0,
      bestAccuracy: json['bestAccuracy']?.toDouble() ?? 0.0,
      totalCharactersTyped: json['totalCharactersTyped'] ?? 0,
      totalErrors: json['totalErrors'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      perfectLessons: json['perfectLessons'] ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? DateTime.parse(json['lastPracticeDate'])
          : DateTime.now(),
      lessonsByLanguage: Map<String, int>.from(json['lessonsByLanguage'] ?? {}),
      recentSessions:
          (json['recentSessions'] as List<dynamic>?)
              ?.map((session) => PracticeSession.fromJson(session))
              .toList() ??
          [],
    );
  }

  static Statistics get empty => Statistics(
    totalLessonsCompleted: 0,
    totalPracticeTime: 0,
    averageWpm: 0.0,
    bestWpm: 0.0,
    averageAccuracy: 0.0,
    bestAccuracy: 0.0,
    totalCharactersTyped: 0,
    totalErrors: 0,
    currentStreak: 0,
    longestStreak: 0,
    perfectLessons: 0,
    lastPracticeDate: DateTime.now(),
    lessonsByLanguage: {},
    recentSessions: [],
  );
}

class PracticeSession {
  final String language;
  final int lessonId;
  final double wpm;
  final double accuracy;
  final int duration; // in seconds
  final int errors;
  final DateTime completedAt;
  final bool isPerfect;

  PracticeSession({
    required this.language,
    required this.lessonId,
    required this.wpm,
    required this.accuracy,
    required this.duration,
    required this.errors,
    required this.completedAt,
    required this.isPerfect,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'lessonId': lessonId,
      'wpm': wpm,
      'accuracy': accuracy,
      'duration': duration,
      'errors': errors,
      'completedAt': completedAt.toIso8601String(),
      'isPerfect': isPerfect,
    };
  }

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      language: json['language'],
      lessonId: json['lessonId'],
      wpm: json['wpm']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
      errors: json['errors'] ?? 0,
      completedAt: DateTime.parse(json['completedAt']),
      isPerfect: json['isPerfect'] ?? false,
    );
  }
}

class StatisticsService {
  static Statistics _statistics = Statistics.empty;

  static Statistics get statistics => _statistics;

  static void updateStatistics(PracticeSession session) {
    final sessions = List<PracticeSession>.from(_statistics.recentSessions);
    sessions.add(session);

    // Keep only last 50 sessions
    if (sessions.length > 50) {
      sessions.removeRange(0, sessions.length - 50);
    }

    final lessonsByLanguage = Map<String, int>.from(
      _statistics.lessonsByLanguage,
    );
    lessonsByLanguage[session.language] =
        (lessonsByLanguage[session.language] ?? 0) + 1;

    final totalLessonsCompleted = _statistics.totalLessonsCompleted + 1;
    final totalPracticeTime =
        _statistics.totalPracticeTime + (session.duration ~/ 60);
    final totalCharactersTyped =
        _statistics.totalCharactersTyped +
        (session.wpm * session.duration / 60 * 5).round();
    final totalErrors = _statistics.totalErrors + session.errors;
    final perfectLessons =
        _statistics.perfectLessons + (session.isPerfect ? 1 : 0);

    // Calculate averages
    final averageWpm =
        sessions.map((s) => s.wpm).reduce((a, b) => a + b) / sessions.length;
    final averageAccuracy =
        sessions.map((s) => s.accuracy).reduce((a, b) => a + b) /
        sessions.length;

    // Update best scores
    final bestWpm = session.wpm > _statistics.bestWpm
        ? session.wpm
        : _statistics.bestWpm;
    final bestAccuracy = session.accuracy > _statistics.bestAccuracy
        ? session.accuracy
        : _statistics.bestAccuracy;

    // Update streak
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    int currentStreak = _statistics.currentStreak;
    int longestStreak = _statistics.longestStreak;

    if (_statistics.lastPracticeDate.isAfter(yesterday)) {
      currentStreak++;
    } else if (_statistics.lastPracticeDate.isBefore(yesterday)) {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    _statistics = Statistics(
      totalLessonsCompleted: totalLessonsCompleted,
      totalPracticeTime: totalPracticeTime,
      averageWpm: averageWpm,
      bestWpm: bestWpm,
      averageAccuracy: averageAccuracy,
      bestAccuracy: bestAccuracy,
      totalCharactersTyped: totalCharactersTyped,
      totalErrors: totalErrors,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      perfectLessons: perfectLessons,
      lastPracticeDate: today,
      lessonsByLanguage: lessonsByLanguage,
      recentSessions: sessions,
    );

    // Check for achievements
    AchievementService.checkAndUnlockAchievements(
      lessonsCompleted: totalLessonsCompleted,
      bestWpm: bestWpm,
      bestAccuracy: bestAccuracy,
      currentStreak: currentStreak,
      perfectLessons: perfectLessons,
    );
  }

  static void resetStatistics() {
    _statistics = Statistics.empty;
  }

  static Map<String, dynamic> toJson() {
    return _statistics.toJson();
  }

  static void fromJson(Map<String, dynamic> json) {
    _statistics = Statistics.fromJson(json);
  }
}
