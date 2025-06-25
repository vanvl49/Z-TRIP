import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/vehicle_unit_model.dart';
import '../services/vehicle_unit_service.dart';

class VehicleUnitController extends GetxController {
  // Reactive state
  final RxList<VehicleUnit> vehicleUnits = <VehicleUnit>[].obs;
  final Rx<VehicleUnit?> selectedVehicleUnit = Rx<VehicleUnit?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Get token from storage (private)
  String? _getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  // Tambahkan getter public
  String? get token => _getToken();

  // =============================================================
  // FETCH ALL VEHICLE UNITS
  // =============================================================
  Future<void> fetchAllVehicleUnits() async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final fetchedUnits = await VehicleUnitService.fetchVehicleUnits(token);
      vehicleUnits.value = fetchedUnits;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat unit kendaraan: $e';
      vehicleUnits.clear();
    }
  }

  // =============================================================
  // FETCH VEHICLE UNIT BY ID
  // =============================================================
  Future<VehicleUnit?> fetchVehicleUnitById(int id) async {
    final token = _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi');
    try {
      final unit = await VehicleUnitService.fetchVehicleUnitById(token, id);
      return unit;
    } catch (e) {
      throw Exception('Gagal memuat detail unit: $e');
    }
  }

  // =============================================================
  // ADD VEHICLE UNIT (ADMIN)
  // =============================================================
  Future<bool> addVehicleUnit({
    required String code,
    required int vehicleId,
    required double pricePerDay,
    String? description,
    Uint8List? imageBytes,
  }) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // PERBAIKAN: Tambahkan parameter yang hilang
      final success = await VehicleUnitService.addVehicleUnit(
        token,
        code: code,
        vehicleId: vehicleId,
        pricePerDay: pricePerDay,
        description: description,
        imageBytes: imageBytes,
      );

      isLoading.value = false;

      if (success) {
        // Refresh vehicle units list
        fetchAllVehicleUnits();
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menambahkan unit: $e';
      return false;
    }
  }

  // =============================================================
  // UPDATE VEHICLE UNIT (ADMIN)
  // =============================================================
  Future<bool> updateVehicleUnit({
    required int id,
    required String code,
    required int vehicleId,
    required double pricePerDay,
    String? description,
  }) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // PERBAIKAN: Tambahkan parameter yang hilang
      final success = await VehicleUnitService.updateVehicleUnit(
        token,
        id,
        code: code,
        vehicleId: vehicleId,
        pricePerDay: pricePerDay,
        description: description,
      );

      isLoading.value = false;

      if (success) {
        // Refresh list and selected unit
        fetchAllVehicleUnits();
        if (selectedVehicleUnit.value?.id == id) {
          fetchVehicleUnitById(id);
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memperbarui unit: $e';
      return false;
    }
  }

  // =============================================================
  // UPLOAD VEHICLE IMAGE (ADMIN)
  // =============================================================
  Future<bool> uploadVehicleImage(int unitId, Uint8List imageBytes) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // PERBAIKAN: Tambahkan parameter yang hilang
      final success = await VehicleUnitService.uploadVehicleImage(
        token,
        unitId,
        imageBytes,
      );

      isLoading.value = false;

      if (success && selectedVehicleUnit.value?.id == unitId) {
        fetchVehicleUnitById(unitId);
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal mengupload gambar: $e';
      return false;
    }
  }

  // =============================================================
  // DELETE VEHICLE UNIT (ADMIN)
  // =============================================================
  Future<bool> deleteVehicleUnit(int id) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // First check if unit has bookings
      final hasBookings = await VehicleUnitService.hasVehicleUnitBookings(
        token,
        id,
      );

      if (hasBookings) {
        isLoading.value = false;
        hasError.value = true;
        errorMessage.value = 'Tidak dapat menghapus unit yang memiliki booking';
        return false;
      }

      final success = await VehicleUnitService.deleteVehicleUnit(token, id);

      isLoading.value = false;

      if (success) {
        // Remove from list and clear selected if it's the deleted one
        vehicleUnits.removeWhere((unit) => unit.id == id);
        if (selectedVehicleUnit.value?.id == id) {
          selectedVehicleUnit.value = null;
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menghapus unit: $e';
      return false;
    }
  }

  // =============================================================
  // DELETE VEHICLE IMAGE (ADMIN)
  // =============================================================
  Future<bool> deleteVehicleImage(int unitId) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      // PERBAIKAN: Tambahkan parameter yang hilang
      final success = await VehicleUnitService.deleteVehicleImage(
        token,
        unitId,
      );

      isLoading.value = false;

      if (success && selectedVehicleUnit.value?.id == unitId) {
        fetchVehicleUnitById(unitId);
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menghapus gambar: $e';
      return false;
    }
  }

  // Get vehicle image URL helper
  String getVehicleImageUrl(int unitId) {
    return VehicleUnitService.getVehicleImageUrl(unitId);
  }

  // Clear selected vehicle unit
  void clearSelectedVehicleUnit() {
    selectedVehicleUnit.value = null;
  }

  // Tambahkan atau perbaiki metode untuk mendapatkan unit kendaraan
  Future<List<VehicleUnit>> getVehicleUnits() async {
    final token = _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    try {
      final fetchedUnits = await VehicleUnitService.fetchVehicleUnits(token);
      vehicleUnits.value = fetchedUnits;
      return fetchedUnits;
    } catch (e) {
      throw Exception('Gagal memuat unit kendaraan: $e');
    }
  }
}
