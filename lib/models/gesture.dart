// lib/models/gesture.dart
class Gesture {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String? imageBase64;
  final String category; // категория жеста (базовый, приветствие и т.д.)
  final bool isLearned; // добавляем поле для отслеживания изученных жестов

  Gesture({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.imageBase64,
    this.category = 'basic',
    this.isLearned = false,
  });

  factory Gesture.fromJson(Map<String, dynamic> json) {
    return Gesture(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imagePath: json['imagePath'],
      imageBase64: json['imageBase64'],
      category: json['category'] ?? 'basic',
      isLearned: json['isLearned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'imageBase64': imageBase64,
      'category': category,
      'isLearned': isLearned,
    };
  }

  // Метод для создания копии с измененными параметрами
  Gesture copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? imageBase64,
    String? category,
    bool? isLearned,
  }) {
    return Gesture(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
      category: category ?? this.category,
      isLearned: isLearned ?? this.isLearned,
    );
  }
}