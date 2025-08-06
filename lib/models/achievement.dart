class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredValue,
    AchievementType? type,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredValue: requiredValue ?? this.requiredValue,
      type: type ?? this.type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'requiredValue': requiredValue,
      'type': type.toString(),
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      requiredValue: json['requiredValue'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

enum AchievementType {
  lessonsCompleted,
  totalWpm,
  accuracy,
  typingStreak,
  perfectLessons,
  speedMaster,
  accuracyMaster,
  marathonRunner,
}

class AchievementService {
  static final List<Achievement> _achievements = [
    // Lesson Completion Achievements
    Achievement(
      id: 'first_lesson',
      title: 'First Steps',
      description: 'Complete your first lesson',
      icon: '🎯',
      requiredValue: 1,
      type: AchievementType.lessonsCompleted,
    ),
    Achievement(
      id: 'lesson_master',
      title: 'Lesson Master',
      description: 'Complete 10 lessons',
      icon: '📚',
      requiredValue: 10,
      type: AchievementType.lessonsCompleted,
    ),
    Achievement(
      id: 'lesson_expert',
      title: 'Lesson Expert',
      description: 'Complete 25 lessons',
      icon: '🏆',
      requiredValue: 25,
      type: AchievementType.lessonsCompleted,
    ),

    // WPM Achievements
    Achievement(
      id: 'speed_beginner',
      title: 'Speed Beginner',
      description: 'Achieve 30 WPM',
      icon: '⚡',
      requiredValue: 30,
      type: AchievementType.totalWpm,
    ),
    Achievement(
      id: 'speed_intermediate',
      title: 'Speed Intermediate',
      description: 'Achieve 50 WPM',
      icon: '🚀',
      requiredValue: 50,
      type: AchievementType.totalWpm,
    ),
    Achievement(
      id: 'speed_master',
      title: 'Speed Master',
      description: 'Achieve 80 WPM',
      icon: '💨',
      requiredValue: 80,
      type: AchievementType.totalWpm,
    ),

    // Accuracy Achievements
    Achievement(
      id: 'accuracy_beginner',
      title: 'Accuracy Beginner',
      description: 'Achieve 90% accuracy',
      icon: '🎯',
      requiredValue: 90,
      type: AchievementType.accuracy,
    ),
    Achievement(
      id: 'accuracy_master',
      title: 'Accuracy Master',
      description: 'Achieve 98% accuracy',
      icon: '🎯',
      requiredValue: 98,
      type: AchievementType.accuracy,
    ),

    // Streak Achievements
    Achievement(
      id: 'streak_3',
      title: 'Consistent',
      description: 'Complete 3 lessons in a row',
      icon: '🔥',
      requiredValue: 3,
      type: AchievementType.typingStreak,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Dedicated',
      description: 'Complete 7 lessons in a row',
      icon: '🔥',
      requiredValue: 7,
      type: AchievementType.typingStreak,
    ),

    // Perfect Lessons
    Achievement(
      id: 'perfect_1',
      title: 'Perfect Start',
      description: 'Complete a lesson with 100% accuracy',
      icon: '✨',
      requiredValue: 1,
      type: AchievementType.perfectLessons,
    ),
    Achievement(
      id: 'perfect_5',
      title: 'Perfect Master',
      description: 'Complete 5 lessons with 100% accuracy',
      icon: '✨',
      requiredValue: 5,
      type: AchievementType.perfectLessons,
    ),
  ];

  static List<Achievement> get achievements => _achievements;

  static List<Achievement> getUnlockedAchievements() {
    return _achievements
        .where((achievement) => achievement.isUnlocked)
        .toList();
  }

  static List<Achievement> getLockedAchievements() {
    return _achievements
        .where((achievement) => !achievement.isUnlocked)
        .toList();
  }

  static void unlockAchievement(String id) {
    final index = _achievements.indexWhere(
      (achievement) => achievement.id == id,
    );
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = _achievements[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
    }
  }

  static void checkAndUnlockAchievements({
    required int lessonsCompleted,
    required double bestWpm,
    required double bestAccuracy,
    required int currentStreak,
    required int perfectLessons,
  }) {
    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      switch (achievement.type) {
        case AchievementType.lessonsCompleted:
          shouldUnlock = lessonsCompleted >= achievement.requiredValue;
          break;
        case AchievementType.totalWpm:
          shouldUnlock = bestWpm >= achievement.requiredValue;
          break;
        case AchievementType.accuracy:
          shouldUnlock = bestAccuracy >= achievement.requiredValue;
          break;
        case AchievementType.typingStreak:
          shouldUnlock = currentStreak >= achievement.requiredValue;
          break;
        case AchievementType.perfectLessons:
          shouldUnlock = perfectLessons >= achievement.requiredValue;
          break;
        default:
          break;
      }

      if (shouldUnlock) {
        unlockAchievement(achievement.id);
      }
    }
  }
}
