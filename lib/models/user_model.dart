class User {
  final String username;
  final String password;
  final String? name;
  final String? profileImage;
  final String role; // 'user' или 'admin'
  final List<String> completedTests; // список ID пройденных тестов
  final List<String> completedGestures; // список ID пройденных жестов
  final List<String> completedNotes; // список ID пройденных конспектов

  User({
    required this.username,
    required this.password,
    this.name,
    this.profileImage,
    this.role = 'user',
    List<String>? completedTests,
    List<String>? completedGestures,
    List<String>? completedNotes,
  })  : this.completedTests = completedTests ?? [],
        this.completedGestures = completedGestures ?? [],
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
      completedGestures: json['completedGestures'] != null
          ? List<String>.from(json['completedGestures'])
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
      'completedGestures': completedGestures,
      'completedNotes': completedNotes,
    };
  }
}