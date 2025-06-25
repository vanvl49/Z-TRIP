import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  void _showImageSourceDialog(
    BuildContext context,
    AuthController authController,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    authController.pickProfileImage(fromCamera: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    authController.pickProfileImage(fromCamera: false);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Z-TRIP'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image Picker
                  Obx(
                    () => GestureDetector(
                      onTap:
                          () => _showImageSourceDialog(context, authController),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          image:
                              authController.profileImageBytes.value != null
                                  ? DecorationImage(
                                    image: MemoryImage(
                                      authController.profileImageBytes.value!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            authController.profileImageBytes.value == null
                                ? const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to add profile photo (optional)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    controller: authController.emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextField(
                    controller: authController.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: authController.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Register
                  Obx(
                    () =>
                        authController.isLoading.value
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: () async {
                                if (await authController.register()) {
                                  // Clear controllers
                                  authController.emailController.clear();
                                  authController.passwordController.clear();
                                  authController.nameController.clear();
                                  authController.profileImageBytes.value = null;

                                  // Navigate to login
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
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
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                  ),

                  const SizedBox(height: 16),

                  // Kembali ke Login
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sudah punya akun? Login',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
