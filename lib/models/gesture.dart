class Gesture {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String category; // категория жеста (базовый, приветствие и т.д.)

  Gesture({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.category = 'basic',
  });

  factory Gesture.fromJson(Map<String, dynamic> json) {
    return Gesture(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imagePath: json['imagePath'],
      category: json['category'] ?? 'basic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'category': category,
    };
  }
}