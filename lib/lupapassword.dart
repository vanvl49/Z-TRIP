import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int currentPage = 0;

  void nextPage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        currentPage++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void prevPage() {
    setState(() {
      currentPage--;
    });
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void resetPassword() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Sukses"),
          content: Text("Password berhasil diubah."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
    }
  }

  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lupa Password",
          style: TextStyle(color: Color(0xffffffff)),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            // Langkah 1: Email
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Langkah 1 dari 3",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  Text("Masukkan Email", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: customInputDecoration("Email", Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email tidak boleh kosong";
                      }
                      if (!value.contains("@")) {
                        return "Format email tidak valid";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      "Kirim Kode Verifikasi",
                      style: TextStyle(color: Color(0xffffffff)),
                    ),
                  ),
                ],
              ),
            ),

            // Langkah 2: Kode Verifikasi
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Langkah 2 dari 3",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  Text("Masukkan Kode Verifikasi",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: codeController,
                    decoration:
                        customInputDecoration("Kode", Icons.verified_user),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Kode verifikasi wajib diisi";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: prevPage,
                          child: Text("Kembali"),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                          child: Text(
                            "Lanjut",
                            style: TextStyle(
                              color: Color(0xffffffff),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Langkah 3: Password Baru
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Langkah 3 dari 3",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  Text("Buat Password Baru", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration:
                        customInputDecoration("Password Baru", Icons.lock),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return "Password minimal 6 karakter";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: customInputDecoration(
                        "Konfirmasi Password", Icons.lock_outline),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return "Konfirmasi password tidak cocok";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: prevPage,
                          child: Text("Kembali"),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                          child: Text(
                            "Reset Password",
                            style: TextStyle(
                              color: Color(0xffffffff),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
