// lib/models/test_model.dart
class Test {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String category;

  Test({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.category = 'basic',
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'],
      category: json['category'] ?? 'basic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'category': category,
    };
  }

  // Метод для создания копии с измененными параметрами
  Test copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctOptionIndex,
    String? category,
  }) {
    return Test(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? List<String>.from(this.options),
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      category: category ?? this.category,
    );
  }

  // Проверка правильности ответа
  bool isCorrectAnswer(int selectedIndex) {
    return selectedIndex == correctOptionIndex;
  }

  // Получение правильного ответа
  String get correctAnswer {
    if (correctOptionIndex >= 0 && correctOptionIndex < options.length) {
      return options[correctOptionIndex];
    }
    return '';
  }

  // Валидация теста
  bool get isValid {
    return question.isNotEmpty &&
        options.length >= 2 &&
        correctOptionIndex >= 0 &&
        correctOptionIndex < options.length &&
        options.every((option) => option.isNotEmpty);
  }
}