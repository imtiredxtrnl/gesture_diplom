class AlphabetLetter {
  final String id;
  final String letter;
  final String language; // 'uk' или 'en'
  final String imagePath;

  AlphabetLetter({
    required this.id,
    required this.letter,
    required this.language,
    required this.imagePath,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    return AlphabetLetter(
      id: json['id'],
      letter: json['letter'],
      language: json['language'],
      imagePath: json['imagePath'],
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
}