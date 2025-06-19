class User {
  final String username;
  final String password;
  final String? name;
  final String? profileImage;
  final String role; // 'user' или 'admin'
  final List<String> completedTests; // список ID пройденных тестов
  final List<String> completedNotes; // список ID пройденных конспектов

  User({
    required this.username,
    required this.password,
    this.name,
    this.profileImage,
    this.role = 'user',
    List<String>? completedTests,
    List<String>? completedNotes,
  })  : this.completedTests = completedTests ?? [],
        this.completedNotes = completedNotes ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      name: json['name'],
      profileImage: json['profileImage'],
      role: json['role'] ?? 'user',
      completedTests: json['completedTests'] != null
          ? List<String>.from(json['completedTests'])
          : [],
      completedNotes: json['completedNotes'] != null
          ? List<String>.from(json['completedNotes'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'profileImage': profileImage,
      'role': role,
      'completedTests': completedTests,
      'completedNotes': completedNotes,
    };
  }
}