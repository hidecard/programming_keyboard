class CustomLesson {
  final String id;
  final String title;
  final String description;
  final String language;
  final String code;
  final String difficulty;
  final DateTime createdAt;
  final bool isPublic;

  CustomLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.code,
    required this.difficulty,
    required this.createdAt,
    this.isPublic = false,
  });

  CustomLesson copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? code,
    String? difficulty,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return CustomLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      code: code ?? this.code,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'code': code,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  factory CustomLesson.fromJson(Map<String, dynamic> json) {
    return CustomLesson(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      language: json['language'],
      code: json['code'],
      difficulty: json['difficulty'],
      createdAt: DateTime.parse(json['createdAt']),
      isPublic: json['isPublic'] ?? false,
    );
  }
}

class CustomLessonService {
  static final List<CustomLesson> _customLessons = [];

  static List<CustomLesson> get customLessons => List.unmodifiable(_customLessons);

  static void addCustomLesson(CustomLesson lesson) {
    _customLessons.add(lesson);
  }

  static void removeCustomLesson(String id) {
    _customLessons.removeWhere((lesson) => lesson.id == id);
  }

  static CustomLesson? getCustomLesson(String id) {
    try {
      return _customLessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<CustomLesson> getLessonsByLanguage(String language) {
    return _customLessons.where((lesson) => lesson.language == language).toList();
  }

  static List<CustomLesson> getPublicLessons() {
    return _customLessons.where((lesson) => lesson.isPublic).toList();
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static List<Map<String, dynamic>> toJsonList() {
    return _customLessons.map((lesson) => lesson.toJson()).toList();
  }

  static void fromJsonList(List<dynamic> jsonList) {
    _customLessons.clear();
    for (final json in jsonList) {
      _customLessons.add(CustomLesson.fromJson(json));
    }
  }
} 