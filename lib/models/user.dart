class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? role;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
    };
  }
}
