class TestQuestion {
  final String id;
  final String question;
  final String? gestureId;
  final String? gestureName;
  final String? gestureImagePath;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  TestQuestion({
    required this.id,
    required this.question,
    this.gestureId,
    this.gestureName,
    this.gestureImagePath,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'],
      question: json['question'],
      gestureId: json['gestureId'],
      gestureName: json['gestureName'],
      gestureImagePath: json['gestureImagePath'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'gestureId': gestureId,
      'gestureName': gestureName,
      'gestureImagePath': gestureImagePath,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

class TestAnswer {
  final String questionId;
  final int selectedOptionIndex;
  final bool isCorrect;
  final DateTime answeredAt;

  TestAnswer({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory TestAnswer.fromJson(Map<String, dynamic> json) {
    return TestAnswer(
      questionId: json['questionId'],
      selectedOptionIndex: json['selectedOptionIndex'],
      isCorrect: json['isCorrect'],
      answeredAt: DateTime.parse(json['answeredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionIndex': selectedOptionIndex,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

class TestResult {
  final String id;
  final String testId;
  final String userId;
  final List<TestAnswer> answers;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final Duration timeSpent;

  TestResult({
    required this.id,
    required this.testId,
    required this.userId,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    required this.timeSpent,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testId: json['testId'],
      userId: json['userId'],
      answers: (json['answers'] as List)
          .map((answer) => TestAnswer.fromJson(answer))
          .toList(),
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      completedAt: DateTime.parse(json['completedAt']),
      timeSpent: Duration(seconds: json['timeSpent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'userId': userId,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'completedAt': completedAt.toIso8601String(),
      'timeSpent': timeSpent.inSeconds,
    };
  }

  double get percentage => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

  bool get isPassed => score >= 70; // 70% для прохождения
}