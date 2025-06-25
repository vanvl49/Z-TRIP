class RegisterModel {
  final String email;
  final String name;
  final String password;
  final List<int>? profileImageBytes; // New field for profile image data

  RegisterModel({
    required this.email,
    required this.name,
    required this.password,
    this.profileImageBytes,
  });

  // No toJson needed as we'll use FormData instead
}
