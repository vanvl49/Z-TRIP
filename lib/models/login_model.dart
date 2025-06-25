// Sesuaikan dengan nama class di C# (Login)
class Login {
  final String email;
  final String password;

  Login({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// Untuk backward compatibility, bisa ditambahkan alias
typedef LoginModel = Login;
