class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime? emailVerifiedAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.emailVerifiedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      status: json['status']?.toString() ?? '',
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.tryParse(json['emailVerifiedAt'].toString())
          : null,
    );
  }
}
