import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rentalkuy/controllers/admin_controller.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/booking_controller.dart';
import 'package:rentalkuy/models/booking_model.dart';
import 'package:rentalkuy/services/transaction_service.dart';
import 'package:rentalkuy/services/tracking_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'tracking_page.dart';
import 'package:rentalkuy/views/pages/admin_verify_customers_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = Get.find<AuthController>();
  final BookingController _bookingController = Get.put(BookingController());
  final AdminController _adminController = Get.put(AdminController());

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _startLocationTracking();
    });
    _authController.refreshUserProfile();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _bookingController.loadBookings();
      _bookingController.hasError.value = false;
      _bookingController.errorMessage.value = '';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Anda belum memiliki booking')) {
        _bookingController.hasError.value = false;
        _bookingController.errorMessage.value = '';
        _bookingController.bookings.clear();
      } else {
        _bookingController.hasError.value = true;
        _bookingController.errorMessage.value = msg;
      }
    }
  }

  // ================== TRACKING CUSTOMER LOCATION ==================
  void _startLocationTracking() async {
    if (_authController.isAdmin) return;

    Future<void> sendAllLocations() async {
      for (final booking in _bookingController.bookings) {
        final now = DateTime.now();
        if (now.isAfter(booking.startDatetime) &&
            now.isBefore(booking.endDatetime.add(const Duration(days: 1)))) {
          await _sendLocation(booking.id);
        }
      }
    }

    await sendAllLocations();

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      print('[TRACKING] Timer trigger: kirim lokasi ulang');
      await sendAllLocations();
    });
  }

  Future<void> _sendLocation(int bookingId) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition();
      final token = _authController.getToken();
      if (token == null) return;

      await TrackingService.createTracking(
        token,
        bookingId,
        pos.latitude.toString(),
        pos.longitude.toString(),
      );
    } catch (e) {
      print('❌ Gagal mengirim lokasi: $e');
    }
  }
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_authController.isAdmin ? 'Admin Dashboard' : 'Bookings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.orange),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _authController.currentUser.value?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _authController.isAdmin ? 'Admin' : 'Customer',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (_authController.isAdmin)
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('Verify Customers'),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const AdminVerifyCustomersPage());
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _authController.logout();
                Navigator.pop(context);
                Get.offAllNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Obx(() {
          if (_bookingController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_bookingController.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${_bookingController.errorMessage.value}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          if (_bookingController.bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _authController.isAdmin
                        ? 'Tidak ada booking yang tersedia'
                        : 'Anda belum memiliki booking',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children:
                _groupBookingsByStatus(_bookingController.bookings).entries.map(
                  (entry) {
                    final status = entry.key;
                    final bookings = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                        ...bookings.map(_buildBookingCard).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ).toList(),
          );
        }),
      ),
    );
  }

  void _debugBookingData(Booking booking) {
    print('=====================================================');
    print('DEBUG BOOKING ID: ${booking.id}');
    print('Vehicle Info: ${booking.vehicle}');
    print('Transaction ID: ${booking.transactionId}');
    print('Transaction Data: ${booking.transaction}');
    if (booking.transaction != null) {
      print('Payment Status: ${booking.transaction!['paymentStatus']}');
      print('Amount: ${booking.transaction!['amount']}');
      print('Payment Image URL: ${booking.transaction!['paymentImageUrl']}');
    }
    print('=====================================================');
  }

  Widget _buildBookingCard(Booking booking) {
    final transaction = booking.transaction;
    final vehicleName =
        booking.vehicle != null
            ? [booking.vehicle!['merk'], booking.vehicle!['name']]
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .join(' ')
            : (booking.vehicle is String && booking.vehicle != null)
            ? booking.vehicle.toString()
            : 'Unknown Vehicle';

    final vehicleUnitCode =
        booking.vehicleUnit?['code'] ??
        booking.vehicle?['unitCode'] ??
        booking.vehicleUnitId?.toString() ??
        '-';

    final pricePerDay =
        transaction?['pricePerDay'] ?? booking.vehicleUnit?['pricePerDay'] ?? 0;

    final start = booking.startDatetime;
    final end = booking.endDatetime;
    final duration = end.difference(start).inDays + 1;

    final totalAmount =
        [
              transaction?['amount'],
              transaction?['totalPrice'],
              transaction?['price'],
            ]
            .firstWhere(
              (v) => v != null && v.toString() != '0',
              orElse: () => 0,
            )
            .toDouble();

    final paymentImageUrl =
        transaction?['paymentImageUrl'] ??
        (booking.transactionId != null
            ? TransactionService.getPaymentImageUrl(booking.transactionId!)
            : null);

    final bookingId = booking.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚘 $vehicleName ($vehicleUnitCode)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '📅 ${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
            ),
            Text('⏳ $duration hari'),
            const SizedBox(height: 8),
            Text(
              '💰 Total: Rp ${NumberFormat('#,##0').format(totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Booking ID selalu tampil untuk semua user
            Text(
              'Booking ID: $bookingId',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Text('🧾 Status: ${booking.status.name.toUpperCase()}'),
            const SizedBox(height: 12),

            if (paymentImageUrl != null &&
                paymentImageUrl.toString().isNotEmpty)
              GestureDetector(
                onTap:
                    () async => await _showFullImage(context, paymentImageUrl),
                child: const Text(
                  'Lihat bukti pembayaran',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            if (_authController.isAdmin &&
                DateTime.now().isAfter(booking.startDatetime) &&
                DateTime.now().isBefore(
                  booking.endDatetime.add(const Duration(days: 1)),
                ))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.location_on, color: Colors.blue),
                  label: const Text('Lihat Lokasi Customer'),
                  onPressed: () {
                    Get.to(() => TrackingPage(bookingId: booking.id));
                  },
                ),
              ),

            if (_authController.isAdmin &&
                booking.transactionId != null &&
                paymentImageUrl != null &&
                booking.status == BookingStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _approvePayment(booking),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text("Setujui"),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _rejectBooking(booking),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Tolak"),
                    ),
                  ],
                ),
              ),

            if (_authController.isAdmin &&
                booking.status == BookingStatus.approved &&
                DateTime.now().isAfter(booking.startDatetime) &&
                DateTime.now().isBefore(
                  booking.endDatetime.add(const Duration(days: 1)),
                ))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Mulai Booking (Set On Going)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Mulai Booking'),
                        content: const Text(
                          'Apakah Anda yakin ingin memulai booking ini (set status on_going)?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text('Mulai'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final success = await _bookingController.startBooking(
                        booking.id,
                      );
                      if (success) {
                        Get.snackbar(
                          'Berhasil',
                          'Booking sudah dimulai (status on_going)',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                        await _loadData();
                      } else {
                        Get.snackbar(
                          'Gagal',
                          _bookingController.errorMessage.value,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullImage(BuildContext context, String imageUrl) async {
    final token = await _authController.getToken();

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;

        showDialog(
          context: context,
          builder:
              (_) => Dialog(
                backgroundColor: Colors.black,
                insetPadding: const EdgeInsets.all(10),
                child: InteractiveViewer(
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                ),
              ),
        );
      } else {
        throw Exception('Gagal memuat gambar: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error memuat gambar: $e');
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Gagal Memuat'),
              content: Text(
                'Terjadi kesalahan saat menampilkan bukti pembayaran.',
              ),
            ),
      );
    }
  }

  Future<void> _approvePayment(Booking booking) async {
    if (booking.transactionId == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Konfirmasi Setujui Pembayaran'),
        content: const Text(
          'Apakah Anda yakin ingin menyetujui pembayaran booking ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final success = await _bookingController.approveBooking(booking.id);
      if (success) {
        Get.snackbar(
          'Berhasil',
          'Pembayaran telah disetujui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await _loadData();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyetujui pembayaran: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    final TextEditingController reasonController = TextEditingController(
      text: "Ditolak oleh admin",
    );
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Konfirmasi Penolakan Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan alasan penolakan booking ini:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final success = await _bookingController.rejectBooking(
        booking.id,
        reason:
            reasonController.text.trim().isEmpty
                ? "Ditolak oleh admin"
                : reasonController.text.trim(),
      );
      if (success) {
        Get.snackbar(
          'Berhasil',
          'Booking ditolak',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await _loadData();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menolak booking: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.approved:
        return Colors.blue;
      case BookingStatus.on_going:
        return Colors.green;
      case BookingStatus.done:
        return Colors.purple;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.overtime:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Menunggu';
      case BookingStatus.approved:
        return 'Disetujui';
      case BookingStatus.on_going:
        return 'Berlangsung';
      case BookingStatus.done:
        return 'Selesai';
      case BookingStatus.rejected:
        return 'Ditolak';
      case BookingStatus.overtime:
        return 'Terlambat';
      default:
        return 'Unknown';
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'unpaid':
        return 'Belum Dibayar';
      case 'pending':
        return 'Menunggu Verifikasi';
      default:
        return status;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.warning;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Map<BookingStatus, List<Booking>> _groupBookingsByStatus(
    List<Booking> bookings,
  ) {
    final Map<BookingStatus, List<Booking>> grouped = {};
    for (final booking in bookings) {
      grouped.putIfAbsent(booking.status, () => []).add(booking);
    }
    final ordered = <BookingStatus, List<Booking>>{};
    for (final s in [
      BookingStatus.pending,
      BookingStatus.approved,
      BookingStatus.on_going,
      BookingStatus.done,
      BookingStatus.rejected,
      BookingStatus.overtime,
    ]) {
      if (grouped.containsKey(s)) ordered[s] = grouped[s]!;
    }
    return ordered.isNotEmpty ? ordered : grouped;
  }
}
