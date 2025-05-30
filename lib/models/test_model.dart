// lib/models/test_model.dart
class Test {
  final String id;
  final String question;
  final String imagePath;
  final List<String> options;
  final int correctOptionIndex;
  final String category;

  Test({
    required this.id,
    required this.question,
    this.imagePath = '', // Значение по умолчанию
    required this.options,
    required this.correctOptionIndex,
    this.category = 'basic',
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      imagePath: json['imagePath'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      category: json['category'] ?? 'basic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'imagePath': imagePath,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'category': category,
    };
  }

  // Метод для создания копии с изменениями
  Test copyWith({
    String? id,
    String? question,
    String? imagePath,
    List<String>? options,
    int? correctOptionIndex,
    String? category,
  }) {
    return Test(
      id: id ?? this.id,
      question: question ?? this.question,
      imagePath: imagePath ?? this.imagePath,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'Test{id: $id, question: $question, category: $category}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Test &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}