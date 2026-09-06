import '../../models/models.dart';

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'PARENT':
      return UserRole.parent;
    case 'CHILD':
      return UserRole.child;
    case 'ADULT':
      return UserRole.adult;
    default:
      throw ArgumentError('Unknown role: $value');
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.parent:
      return 'PARENT';
    case UserRole.child:
      return 'CHILD';
    case UserRole.adult:
      return 'ADULT';
  }
}

/// Profile shape returned by the backend, distinct from the app's local
/// [AppUser] presentation model.
class BackendUser {
  BackendUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.age,
    required this.isFemale,
    required this.avatarIndex,
    this.phone,
  });

  final String id;
  final String email;
  final UserRole role;
  final String name;
  final int age;
  final bool isFemale;
  final int avatarIndex;
  final String? phone;

  factory BackendUser.fromJson(Map<String, dynamic> json) {
    return BackendUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: userRoleFromString(json['role'] as String),
      name: json['name'] as String,
      age: json['age'] as int,
      isFemale: json['isFemale'] as bool,
      avatarIndex: json['avatarIndex'] as int,
      phone: json['phone'] as String?,
    );
  }

  AppUser toAppUser() => AppUser(
    id: id,
    name: name,
    age: age,
    isFemale: isFemale,
    avatarIndex: avatarIndex,
    phone: phone ?? '',
    email: email,
  );
}
