class User {
  final String username;
  final String password;
  final String? profileImage;
  final String role; // 'user' или 'admin'
  final List<String> completedTests; // список ID пройденных тестов

  User({
    required this.username,
    required this.password,
    this.profileImage,
    this.role = 'user',
    List<String>? completedTests,
  }) : this.completedTests = completedTests ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      profileImage: json['profileImage'],
      role: json['role'] ?? 'user',
      completedTests: json['completedTests'] != null
          ? List<String>.from(json['completedTests'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'profileImage': profileImage,
      'role': role,
      'completedTests': completedTests,
    };
  }
}