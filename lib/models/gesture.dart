// lib/models/gesture.dart
class Gesture {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String category;
  final bool? isLearned; // Опциональное поле для отслеживания изученности

  Gesture({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.category = 'basic',
    this.isLearned,
  });

  factory Gesture.fromJson(Map<String, dynamic> json) {
    return Gesture(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imagePath: json['imagePath'],
      category: json['category'] ?? 'basic',
      isLearned: json['isLearned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'category': category,
      'isLearned': isLearned,
    };
  }

  // Метод для создания копии с изменениями
  Gesture copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? category,
    bool? isLearned,
  }) {
    return Gesture(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isLearned: isLearned ?? this.isLearned,
    );
  }
}