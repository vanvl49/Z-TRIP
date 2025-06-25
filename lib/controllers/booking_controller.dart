import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../controllers/transaction_controller.dart';
import '../services/vehicle_unit_service.dart';
import 'auth_guard_mixin.dart';

class BookingController extends GetxController with AuthGuardMixin {
  final RxList<Booking> bookings = <Booking>[].obs;
  final Rx<Booking?> selectedBooking = Rx<Booking?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBookings();
  }

  // Ambil semua booking (customer/admin) dan join dengan vehicle unit
  Future<void> loadBookings() async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      // Ambil semua booking
      final fetchedBookings = await BookingService.getBookings(token);

      // TAMBAHKAN PENGECEKAN NULL
      // Jika tidak ada booking, kembalikan list kosong
      if (fetchedBookings.isEmpty) {
        bookings.value = [];
        isLoading.value = false;
        return;
      }

      // Ambil semua vehicle unit
      final vehicleUnits = await VehicleUnitService.fetchVehicleUnits(token);
      final unitMap = {for (var unit in vehicleUnits) unit.id: unit.toJson()};

      // Isi field vehicleUnit pada setiap booking
      final bookingsWithUnit =
          fetchedBookings.map((booking) {
            // TAMBAHKAN PENGECEKAN TIPE
            final unitJson =
                booking.vehicleUnitId != null
                    ? unitMap[booking.vehicleUnitId]
                    : null;

            return Booking(
              id: booking.id,
              userId: booking.userId,
              vehicleUnitId: booking.vehicleUnitId,
              startDatetime: booking.startDatetime,
              endDatetime: booking.endDatetime,
              status: booking.status,
              statusNote: booking.statusNote,
              transactionId: booking.transactionId,
              requestDate: booking.requestDate,
              // TAMBAHKAN PENGECEKAN TIPE
              vehicle:
                  (booking.vehicle != null &&
                          booking.vehicle is Map<String, dynamic>)
                      ? booking.vehicle
                      : (booking.vehicle != null
                          ? {'name': booking.vehicle.toString()}
                          : null),

              vehicleUnit:
                  unitJson, // hasil join, pastikan Map<String, dynamic>
              user: booking.user is Map<String, dynamic> ? booking.user : null,
              transaction:
                  booking.transaction is Map<String, dynamic>
                      ? booking.transaction
                      : null,
            );
          }).toList();

      bookings.value = bookingsWithUnit;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat booking: $e';
      bookings.clear();
    }
  }

  // Ambil booking berdasarkan ID
  Future<void> fetchBookingById(int bookingId) async {
    try {
      isLoading(true);
      hasError(false);
      errorMessage('');

      final token = getToken();

      if (token == null || token.isEmpty) {
        handleNoToken();
        throw Exception('Token tidak tersedia');
      }

      final booking = await BookingService.getBookingById(token, bookingId);

      selectedBooking(booking);
      isLoading(false);
    } catch (e) {
      hasError(true);
      errorMessage(e.toString());
      isLoading(false);
    }
  }

  // Ambil booking berdasarkan status
  Future<void> loadBookingsByStatus(String status) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final fetchedBookings = await BookingService.getBookingsByStatus(
        token,
        status,
      );
      bookings.value = fetchedBookings;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat booking: $e';
      bookings.clear();
    }
  }

  // Ambil booking berdasarkan vehicle unit
  Future<void> loadBookingsByVehicleUnit(int vehicleUnitId) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final fetchedBookings = await BookingService.getBookingsByVehicleUnit(
        token,
        vehicleUnitId,
      );
      bookings.value = fetchedBookings;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat booking: $e';
      bookings.clear();
    }
  }

  // Ambil semua booking dengan detail vehicle unit
  Future<void> loadBookingsWithVehicleUnits() async {
    isLoading.value = true;
    try {
      final token = getToken();
      if (token == null) {
        handleNoToken();
        throw Exception('Silakan login terlebih dahulu');
      }
      // Jangan assign ke this.bookings.value jika hasilnya Map
      final bookings = await BookingService.getBookings(token);
      final vehicleUnits = await VehicleUnitService.fetchVehicleUnits(token);
      final unitMap = {for (var unit in vehicleUnits) unit.id: unit};

      // Jika ingin join, lakukan di UI:
      // final bookingsWithUnit = bookings.map((booking) {
      //   final unit = unitMap[booking.vehicleUnitId];
      //   return {'booking': booking, 'vehicleUnit': unit};
      // }).toList();

      this.bookings.value = bookings; // Tetap RxList<Booking>
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat booking dengan detail unit: $e';
    }
  }

  // Approve booking (admin)
  Future<bool> approveBooking(int bookingId) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }
    isLoading.value = true;
    try {
      final result = await BookingService.approveBooking(token, bookingId);
      await loadBookings();
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Gagal menyetujui booking: $e';
      return false;
    }
  }

  // Membuat booking baru (dengan/ tanpa bukti pembayaran)
  Future<Booking> createBooking(
    int vehicleUnitId,
    String startDate,
    String endDate, {
    String? note,
    Uint8List? paymentProof,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final token = getToken();
      if (token == null) {
        handleNoToken();
        throw Exception('Silakan login terlebih dahulu');
      }
      final newBooking = await BookingService.createBooking(
        token,
        vehicleUnitId,
        startDate,
        endDate,
        note: note,
      );
      if (paymentProof != null && newBooking.transactionId != null) {
        await Get.find<TransactionController>().uploadPaymentProof(
          newBooking.transactionId!,
          paymentProof,
        );
      }
      await loadBookings();
      return newBooking;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Reject booking (admin)
  Future<bool> rejectBooking(
    int bookingId, {
    String reason = "Ditolak oleh admin",
  }) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      // Panggil BookingService.rejectBooking hanya dengan token & bookingId
      final success = await BookingService.rejectBooking(token, bookingId);
      isLoading.value = false;
      await loadBookings();
      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menolak booking: $e';
      return false;
    }
  }

  // Start booking (ubah status menjadi on_going)
  Future<bool> startBooking(int bookingId) async {
    final token = getToken();
    if (token == null) {
      handleNoToken();
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }
    isLoading.value = true;
    try {
      final result = await BookingService.startBooking(token, bookingId);
      await loadBookings(); // Refresh data setelah status berubah
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Gagal memulai booking: $e';
      return false;
    }
  }
}
