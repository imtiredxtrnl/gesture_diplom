// lib/models/alphabet_letter.dart
class AlphabetLetter {
  final String id;
  final String letter;
  final String language; // 'uk' или 'en'
  final String imagePath;

  AlphabetLetter({
    required this.id,
    required this.letter,
    required this.language,
    this.imagePath = '', // Значение по умолчанию
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    return AlphabetLetter(
      id: json['id'] ?? '',
      letter: json['letter'] ?? '',
      language: json['language'] ?? 'uk',
      imagePath: json['imagePath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'letter': letter,
      'language': language,
      'imagePath': imagePath,
    };
  }

  // Метод для создания копии с изменениями
  AlphabetLetter copyWith({
    String? id,
    String? letter,
    String? language,
    String? imagePath,
  }) {
    return AlphabetLetter(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      language: language ?? this.language,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'AlphabetLetter{id: $id, letter: $letter, language: $language}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AlphabetLetter &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}