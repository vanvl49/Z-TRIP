import 'package:get/get.dart';
import 'package:rentalkuy/models/user_model.dart';
import 'package:rentalkuy/services/admin_service.dart';
import 'package:rentalkuy/controllers/auth_guard_mixin.dart';

class AdminController extends GetxController with AuthGuardMixin {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<User> pendingVerificationUsers = <User>[].obs;
  final RxList<User> customersNeedingVerification = <User>[].obs;

  Future<void> loadVerificationRequests() async {
    isLoading.value = true;
    try {
      final token = getToken();
      if (token != null) {
        final users = await AdminService.getCustomersNeedingVerification(token);
        customersNeedingVerification.assignAll(users);
      } else {
        customersNeedingVerification.clear();
        handleNoToken();
      }
    } catch (e) {
      customersNeedingVerification.clear();
      // Optional: handle error
    } finally {
      isLoading.value = false;
    }
  }

  // Verifikasi user
  Future<void> verifyUser(int userId) async {
    isLoading.value = true;
    try {
      final token = getToken();
      if (token != null) {
        await AdminService.verifyCustomer(token, userId);
      } else {
        handleNoToken();
      }
      await loadVerificationRequests(); // refresh list
    } catch (e) {
      // Optional: handle error
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<User>> getCustomersNeedingVerification() async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      return [];
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final users = await AdminService.getCustomersNeedingVerification(token);
      pendingVerificationUsers.value = users;
      isLoading.value = false;
      return users;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat daftar customer: $e';
      return [];
    }
  }

  Future<bool> verifyCustomer(int userId) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      return false;
    }

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final success = await AdminService.verifyCustomer(token, userId);

      // Refresh list after verification
      if (success) {
        await getCustomersNeedingVerification();
      }

      isLoading.value = false;
      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal melakukan verifikasi: $e';
      return false;
    }
  }

  // Tambahkan method lain untuk admin dashboard
}
