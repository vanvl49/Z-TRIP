import 'package:flutter/material.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/views/widgets/bottom_navbar.dart';
import 'package:rentalkuy/views/pages/reset_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authC = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Z-TRIP'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Field Email
            TextField(
              controller: authC.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Field Password
            TextField(
              controller: authC.passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Obx(
              () =>
                  authC.isLoading.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: () async {
                          if (await authC.login()) {
                            Get.offAll(
                              () => const BottomNavBar(),
                            ); // ✅ Konsisten menggunakan GetX
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: const Text(
                'Belum punya akun? Register',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                );
              },
              child: const Text(
                'Lupa password?',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
