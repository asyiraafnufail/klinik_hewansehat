enum UserRole {
  petOwner('pet_owner'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? val) {
    if (val == 'admin') return UserRole.admin;
    return UserRole.petOwner;
  }
}

class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isPetOwner => role == UserRole.petOwner;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role.value,
    };
  }
}
