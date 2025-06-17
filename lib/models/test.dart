// lib/models/test.dart
class Test {
  final String id;
  final String question;
  final List<String> options;
  final String correctOption;
  final String category;

  Test({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.category,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctOption: json['correct_option'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_option': correctOption,
      'category': category,
    };
  }

  Test copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctOption,
    String? category,
  }) {
    return Test(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOption: correctOption ?? this.correctOption,
      category: category ?? this.category,
    );
  }
}

class Question {
  final String id;
  final String text;
  final String correctGestureId;
  final List<String> options;

  Question({
    required this.id,
    required this.text,
    required this.correctGestureId,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      correctGestureId: json['correctGestureId'],
      options: List<String>.from(json['options']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'correctGestureId': correctGestureId,
      'options': options,
    };
  }

  Question copyWith({
    String? id,
    String? text,
    String? correctGestureId,
    List<String>? options,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      correctGestureId: correctGestureId ?? this.correctGestureId,
      options: options ?? this.options,
    );
  }
} 