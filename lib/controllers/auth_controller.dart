import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/base_service.dart';
import '../controllers/profile_controller.dart';
import '../services/profile_service.dart';

class AuthController extends GetxController {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final Rx<Uint8List?> profileImageBytes = Rx<Uint8List?>(null);
  final Rx<Uint8List?> ktpImageBytes = Rx<Uint8List?>(null);
  final Rx<Uint8List?> simImageBytes = Rx<Uint8List?>(null);

  @override
  void onInit() {
    super.onInit();
    // Check if user is already logged in from storage
    checkLoginStatus();
  }

  void checkLoginStatus() {
    final box = GetStorage();
    final token = box.read('token');
    if (token != null) {
      isLoggedIn.value = true;
      // Load user data in the background
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      // This would typically be implemented in a ProfileService
      // For now, we'll just use stored values
      final box = GetStorage();
      final userId = box.read('user_id');
      final name = box.read('name');
      final email = box.read('email');
      final isAdmin = box.read('role') == true;
      final isVerified = box.read('is_verified') == true;

      currentUser.value = User(
        id: userId ?? 0,
        email: email ?? '',
        name: name ?? '',
        isAdmin: isAdmin,
        isVerified: isVerified,
      );
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Pick profile image
  Future<void> pickProfileImage({required bool fromCamera}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      // Baca bytes asli
      final bytes = await image.readAsBytes();

      // Decode image (mendukung HEIC, JPG, PNG, dsb)
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        // Selalu encode ke JPG agar backend menerima
        final jpgBytes = Uint8List.fromList(
          img.encodeJpg(decoded, quality: 85),
        );
        profileImageBytes.value = jpgBytes;
      } else {
        // Fallback: tetap pakai bytes asli (jika decode gagal)
        profileImageBytes.value = bytes;
      }
    }
  }

  // Pick KTP image
  Future<void> pickKtpImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      ktpImageBytes.value = await image.readAsBytes();
    }
  }

  // Pick SIM image
  Future<void> pickSimImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      simImageBytes.value = await image.readAsBytes();
    }
  }

  // Register user
  Future<bool> register() async {
    if (!_validateRegistrationInput()) return false;

    isLoading.value = true;

    try {
      final response = await AuthService.register(
        email: emailController.text.trim(),
        name: nameController.text.trim(),
        password: passwordController.text,
        profileImageBytes: profileImageBytes.value, // hanya ini yang dikirim
        // ktpImageBytes dan simImageBytes dihapus
      );

      isLoading.value = false;

      if (response.statusCode == 201) {
        Get.snackbar(
          'Sukses',
          'Registrasi berhasil, silakan login',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white,
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Terjadi kesalahan saat registrasi';

        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Login user
  Future<bool> login() async {
    if (!_validateLoginInput()) return false;

    isLoading.value = true;

    try {
      if (BaseService.debugMode) {
        print('🔑 Login attempt: ${emailController.text.trim()}');
      }

      final response = await AuthService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final userId = responseData['user_id'];
        final name = responseData['name'];
        final email = responseData['email'];
        final role = responseData['role'];
        final isVerified = responseData['is_verified'] ?? false;

        // Save to storage
        final box = GetStorage();
        box.write('token', token);
        box.write('user_id', userId);
        box.write('name', name);
        box.write('email', email);
        box.write('role', role);
        box.write('is_verified', isVerified);

        // Update state
        isLoggedIn.value = true;
        currentUser.value = User(
          id: userId,
          name: name,
          email: email,
          isAdmin: role == true,
          isVerified: isVerified,
        );

        isLoading.value = false;

        Get.snackbar(
          'Sukses',
          'Login berhasil. Selamat datang, $name!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white,
        );

        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Login gagal';

        isLoading.value = false;

        Get.snackbar(
          'Gagal',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );

        return false;
      }
    } catch (e) {
      isLoading.value = false;

      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );

      return false;
    }
  }

  // Logout user
  void logout() {
    final box = GetStorage();
    box.erase(); // Clear all stored data

    isLoggedIn.value = false;
    currentUser.value = null;

    // Clear controllers
    emailController.clear();
    passwordController.clear();
    nameController.clear();

    // Clear image data
    profileImageBytes.value = null;
    ktpImageBytes.value = null;
    simImageBytes.value = null;

    // Reset ProfileController state
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().resetState();
    }

    Get.offAllNamed('/login'); // Navigate back to login screen
  }

  // Utility method to check if current user is admin
  bool get isAdmin {
    final box = GetStorage();
    // API mengirim role sebagai boolean, jadi lebih baik cek langsung:
    return box.read('role') == true;
  }

  // Getter for token
  String? getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  // Input validation methods
  bool _validateRegistrationInput() {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !email.isEmail) {
      Get.snackbar('Error', 'Email tidak valid');
      return false;
    }

    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama tidak boleh kosong');
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      Get.snackbar('Error', 'Password minimal 6 karakter');
      return false;
    }

    return true;
  }

  bool _validateLoginInput() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      Get.snackbar('Error', 'Email tidak boleh kosong');
      return false;
    }

    // Validasi email dengan regex, mirip dengan API
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar('Error', 'Format email tidak valid');
      return false;
    }

    if (password.isEmpty) {
      Get.snackbar('Error', 'Password tidak boleh kosong');
      return false;
    }

    return true;
  }

  // Clean up controllers on controller disposal
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  bool get isVerified => currentUser.value?.isVerified ?? false;
  bool get hasKtp => currentUser.value?.hasKtp ?? false;
  bool get hasSim => currentUser.value?.hasSim ?? false;

  // Method to save user data to storage
  void saveUserToStorage(User user) {
    final box = GetStorage();
    box.write('user_id', user.id);
    box.write('name', user.name);
    box.write('email', user.email);
    box.write('role', user.isAdmin);
    box.write('is_verified', user.isVerified);
    // Add more fields if needed
  }

  Future<void> refreshUserProfile() async {
    try {
      final token = getToken();
      if (token == null) return;
      final user = await ProfileService.getProfile(token);
      currentUser.value = user;
      // Simpan ke storage jika perlu
      saveUserToStorage(user);
    } catch (e) {
      // Handle error jika perlu
    }
  }
}
