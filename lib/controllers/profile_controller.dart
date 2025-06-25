import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  // Reactive state
  final Rx<User?> userProfile = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Get token from storage
  String? _getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  @override
  void onInit() {
    super.onInit();
    // Load profile on controller initialization if token exists
    loadProfile();
  }

  // =============================================================
  // GET USER PROFILE
  // =============================================================
  Future<void> loadProfile() async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final profile = await ProfileService.getProfile(token);
      userProfile.value = profile;

      // Update storage with latest data
      final box = GetStorage();
      box.write('name', profile.name);
      box.write('is_verified', profile.isVerified);
      box.write('has_profile', profile.hasProfile);
      box.write('has_ktp', profile.hasKtp);
      box.write('has_sim', profile.hasSim);

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat profil: $e';
    }
  }

  // =============================================================
  // UPDATE USER PROFILE
  // =============================================================
  Future<bool> updateProfile(String name) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    if (name.trim().isEmpty) {
      hasError.value = true;
      errorMessage.value = 'Nama tidak boleh kosong';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await ProfileService.updateProfile(token, name);

      isLoading.value = false;

      if (success) {
        // Reload profile after update
        loadProfile();

        // Update local storage
        final box = GetStorage();
        box.write('name', name);
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memperbarui profil: $e';
      return false;
    }
  }

  // =============================================================
  // UPLOAD KTP IMAGE
  // =============================================================
  // Edit fungsi upload untuk debugging yang lebih baik

  // Upload KTP image
  Future<bool> uploadKtpImage(Uint8List imageBytes) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    if (imageBytes.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'File gambar tidak valid';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // Log ukuran file
      print('📷 Attempting to upload KTP image: ${imageBytes.length} bytes');

      final success = await ProfileService.uploadKtpImage(token, imageBytes);

      isLoading.value = false;

      if (success) {
        print('✅ KTP upload successful');
        // Reload profile after upload
        loadProfile();

        // Update local storage
        final box = GetStorage();
        box.write('has_ktp', true);
      } else {
        print('❌ KTP upload failed without exception');
      }

      return success;
    } catch (e) {
      print('❌ KTP upload error: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal mengupload KTP: $e';
      return false;
    }
  }

  // =============================================================
  // UPLOAD SIM IMAGE
  // =============================================================
  // Upload SIM image - Fungsi sama untuk SIM
  Future<bool> uploadSimImage(Uint8List imageBytes) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    if (imageBytes.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'File gambar tidak valid';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // Log ukuran file
      print('📷 Attempting to upload SIM image: ${imageBytes.length} bytes');

      final success = await ProfileService.uploadSimImage(token, imageBytes);

      isLoading.value = false;

      if (success) {
        print('✅ SIM upload successful');
        // Reload profile after upload
        loadProfile();

        // Update local storage
        final box = GetStorage();
        box.write('has_sim', true);
      } else {
        print('❌ SIM upload failed without exception');
      }

      return success;
    } catch (e) {
      print('❌ SIM upload error: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal mengupload SIM: $e';
      return false;
    }
  }

  // =============================================================
  // UPLOAD PROFILE IMAGE
  // =============================================================
  // Upload profile image - Fungsi sama untuk Profile
  Future<bool> uploadProfileImage(Uint8List imageBytes) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    if (imageBytes.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'File gambar tidak valid';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // Log ukuran file
      print(
        '📷 Attempting to upload profile image: ${imageBytes.length} bytes',
      );

      final success = await ProfileService.uploadProfileImage(
        token,
        imageBytes,
      );

      isLoading.value = false;

      if (success) {
        print('✅ Profile upload successful');
        // Reload profile after upload
        loadProfile();

        // Update local storage
        final box = GetStorage();
        box.write('has_profile', true);
      } else {
        print('❌ Profile upload failed without exception');
      }

      return success;
    } catch (e) {
      print('❌ Profile upload error: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal mengupload foto profil: $e';
      return false;
    }
  }

  // =============================================================
  // GET VERIFICATION STATUS
  // =============================================================
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return {'isVerified': false, 'hasKtp': false, 'hasSim': false};
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final status = await ProfileService.getVerificationStatus(token);

      isLoading.value = false;

      // Update local storage
      final box = GetStorage();
      box.write('is_verified', status['isVerified'] ?? false);
      box.write('has_ktp', status['hasKtp'] ?? false);
      box.write('has_sim', status['hasSim'] ?? false);

      return status;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat status verifikasi: $e';
      return {'isVerified': false, 'hasKtp': false, 'hasSim': false};
    }
  }

  // Get image URLs for profile components
  String getKtpImageUrl() {
    return ProfileService.getKtpImageUrl();
  }

  String getSimImageUrl() {
    return ProfileService.getSimImageUrl();
  }

  String getProfileImageUrl() {
    return ProfileService.getProfileImageUrl();
  }

  void resetState() {
    userProfile.value = null;
    isLoading.value = false;
    hasError.value = false;
    errorMessage.value = '';
  }
}
