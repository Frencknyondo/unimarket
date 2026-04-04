class User {
  final String uid;
  final String registrationNo;
  final String email;
  final String fullName;
  final String password;
  final String role;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.registrationNo,
    required this.email,
    required this.fullName,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'registrationNo': registrationNo,
      'email': email,
      'fullName': fullName,
      'password': password,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      registrationNo: map['registrationNo'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'student',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
