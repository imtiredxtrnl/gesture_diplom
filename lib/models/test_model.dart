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
    required this.imagePath,
    required this.options,
    required this.correctOptionIndex,
    this.category = 'basic',
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      question: json['question'],
      imagePath: json['imagePath'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'],
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
}