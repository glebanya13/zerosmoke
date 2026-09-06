enum UserRole { parent, child, adult }

class AppUser {
  AppUser({
    this.id,
    required this.name,
    required this.age,
    required this.isFemale,
    required this.avatarIndex,
    this.phone = '',
    this.email = '',
  });

  /// Backend user id. Null until the profile is loaded from the API.
  String? id;
  String name;
  int age;
  bool isFemale;
  int avatarIndex;
  String phone;
  String email;
}

