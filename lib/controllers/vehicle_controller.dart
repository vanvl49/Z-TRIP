import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/auth_controller.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleController extends GetxController {
  // Reactive state
  final RxList<Vehicle> vehicles = <Vehicle>[].obs;
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Get token from storage
  String? _getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  // Helper untuk handle token error
  void _handleNoToken() {
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().logout();
    } else {
      Get.offAllNamed('/login');
    }
  }

  // =============================================================
  // GET ALL VEHICLES
  // =============================================================
  Future<void> fetchAllVehicles() async {
    final token = _getToken();
    if (token == null) {
      _handleNoToken();
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final fetchedVehicles = await VehicleService.fetchVehicles(token);
      vehicles.value = fetchedVehicles;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat kendaraan: $e';
      vehicles.clear();
    }
  }

  // =============================================================
  // GET VEHICLE BY ID
  // =============================================================
  Future<Vehicle?> fetchVehicleById(int id) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return null;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final vehicle = await VehicleService.fetchVehicleById(token, id);
      selectedVehicle.value = vehicle;
      isLoading.value = false;
      return vehicle;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat detail kendaraan: $e';
      selectedVehicle.value = null;
      return null;
    }
  }

  // =============================================================
  // FILTER VEHICLES
  // =============================================================
  Future<List<Vehicle>> filterVehicles({
    String? category,
    String? merk,
    int? kapasitas,
    double? priceMin,
    double? priceMax,
    String? name,
  }) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return [];
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final filteredVehicles = await VehicleService.filterVehicles(
        token,
        category: category,
        merk: merk,
        kapasitas: kapasitas,
        priceMin: priceMin,
        priceMax: priceMax,
        name: name,
      );

      isLoading.value = false;
      return filteredVehicles;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memfilter kendaraan: $e';
      return [];
    }
  }

  // =============================================================
  // ADD NEW VEHICLE (ADMIN)
  // =============================================================
  Future<bool> addVehicle(Vehicle vehicle) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await VehicleService.addVehicle(token, vehicle);
      isLoading.value = false;

      if (success) {
        // Refresh list after adding
        fetchAllVehicles();
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menambahkan kendaraan: $e';
      return false;
    }
  }

  // =============================================================
  // UPDATE VEHICLE (ADMIN)
  // =============================================================
  Future<bool> updateVehicle(Vehicle vehicle) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await VehicleService.updateVehicle(token, vehicle);
      isLoading.value = false;

      if (success) {
        // Refresh list and selected vehicle after update
        fetchAllVehicles();
        if (selectedVehicle.value?.id == vehicle.id) {
          selectedVehicle.value = vehicle;
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memperbarui kendaraan: $e';
      return false;
    }
  }

  // =============================================================
  // DELETE VEHICLE (ADMIN)
  // =============================================================
  Future<bool> deleteVehicle(int id) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await VehicleService.deleteVehicle(token, id);
      isLoading.value = false;

      if (success) {
        // Remove from list and clear selected if it's the deleted one
        vehicles.removeWhere((vehicle) => vehicle.id == id);
        if (selectedVehicle.value?.id == id) {
          selectedVehicle.value = null;
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menghapus kendaraan: $e';
      return false;
    }
  }

  // Clear selected vehicle
  void clearSelectedVehicle() {
    selectedVehicle.value = null;
  }

  // Tambahkan atau perbaiki metode untuk mendapatkan kendaraan
  Future<List<Vehicle>> getVehicles() async {
    final token = _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    try {
      final fetchedVehicles = await VehicleService.fetchVehicles(token);
      vehicles.value = fetchedVehicles;
      return fetchedVehicles;
    } catch (e) {
      throw Exception('Gagal memuat kendaraan: $e');
    }
  }
}
