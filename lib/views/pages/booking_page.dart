import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/booking_controller.dart';
import 'package:rentalkuy/services/vehicle_availability_service.dart';
import 'package:intl/intl.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:rentalkuy/models/vehicle_unit_model.dart';

class BookingPage extends StatefulWidget {
  final VehicleUnit vehicleUnit;
  final Vehicle vehicle;

  const BookingPage({
    super.key,
    required this.vehicleUnit,
    required this.vehicle,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final AuthController _authController = Get.find<AuthController>();
  final BookingController _bookingController = Get.find<BookingController>();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  final TextEditingController _noteController = TextEditingController();

  bool? _isAvailable;
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _selectedImage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final token = _authController.getToken();
    if (token == null) {
      _showError('Silakan login kembali');
      return;
    }

    setState(() {
      _isLoading = true;
      _isAvailable = null;
      _errorMessage = null;
    });

    try {
      final startDate = _formatDateForApi(_startDate);
      final endDate = _formatDateForApi(_endDate);

      final result = await VehicleAvailabilityService.checkAvailabilityById(
        token,
        widget.vehicleUnit.id,
        startDate: startDate,
        endDate: endDate,
        excludeRejected: true,
        excludeDone: true,
      );

      setState(() {
        _isAvailable = result['isAvailable'] == true;
        _isLoading = false;
      });

      _showMessage(
        _isAvailable == true
            ? 'Jadwal kendaraan tersedia pada tanggal yang dipilih'
            : 'Kendaraan tidak tersedia pada tanggal tersebut',
        _isAvailable == true ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _isAvailable = false;
      });
      _showError('Gagal memeriksa ketersediaan: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      final bytes = await pickedImage.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        _showError('Format gambar tidak didukung');
        return;
      }

      final jpgBytes = img.encodeJpg(originalImage, quality: 85);

      setState(() {
        _selectedImage = Uint8List.fromList(jpgBytes);
      });
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Batal'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _processBooking() async {
    final user = _authController.currentUser.value;
    if (user == null || !user.isVerified || !user.hasKtp || !user.hasSim) {
      _showError(
        'Anda harus mengupload KTP & SIM dan diverifikasi admin sebelum booking!',
      );
      return;
    }

    if (_isAvailable != true) {
      _showError('Silakan cek ketersediaan kendaraan terlebih dahulu!');
      return;
    }

    final now = DateTime.now();
    if (_startDate.isBefore(now)) {
      _showError('Tanggal mulai tidak boleh di masa lalu');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showError(
        'Tanggal selesai harus setelah atau sama dengan tanggal mulai',
      );
      return;
    }

    // Validasi bukti pembayaran wajib
    if (_selectedImage == null) {
      _showError('Bukti pembayaran wajib diupload');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Log untuk debugging
      print('🔍 Memulai proses booking');
      print('🔍 Ukuran gambar: ${_selectedImage!.length} bytes');

      final startFormatted = _formatDateForApi(_startDate);
      final endFormatted = _formatDateForApi(_endDate);

      // Pastikan gambar tidak null sebelum upload
      if (_selectedImage == null || _selectedImage!.isEmpty) {
        throw Exception('Gambar bukti pembayaran tidak valid');
      }

      final booking = await _bookingController.createBooking(
        widget.vehicleUnit.id,
        startFormatted,
        endFormatted,
        note:
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
        paymentProof: _selectedImage,
      );

      setState(() {
        _isLoading = false;
      });

      // Tampilkan dialog sukses dan kembali ke halaman sebelumnya
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Booking Berhasil'),
              content: const Text(
                'Booking kendaraan berhasil dibuat! Admin akan memverifikasi pembayaran Anda.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showError('Gagal membuat booking: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _formatDateForApi(DateTime date) {
    final utcDate = DateTime.utc(date.year, date.month, date.day, 12);
    return DateFormat('yyyyMMdd').format(utcDate);
  }

  String _formatDateForDisplay(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return DateFormat('dd MMMM yyyy').format(localDate);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isAvailable = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentalDays = _endDate.difference(_startDate).inDays + 1;
    final totalPrice = widget.vehicleUnit.pricePerDay * rentalDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Kendaraan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle info
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.vehicle.merk} ${widget.vehicle.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode Unit: ${widget.vehicleUnit.code}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  widget.vehicle.category ==
                                          VehicleCategory.mobil
                                      ? Icons.directions_car
                                      : Icons.motorcycle,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.vehicle.category ==
                                          VehicleCategory.mobil
                                      ? 'Mobil'
                                      : 'Motor',
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.people, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text('${widget.vehicle.capacity} orang'),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Harga per hari:'),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(widget.vehicleUnit.pricePerDay)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date selection
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanggal Sewa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _selectDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_formatDateForDisplay(_startDate)} - ${_formatDateForDisplay(_endDate)}',
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Durasi:'),
                                Text(
                                  '$rentalDays hari',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Harga:'),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(totalPrice)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _checkAvailability,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cek Ketersediaan'),
                              ),
                            ),

                            if (_isAvailable != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      _isAvailable == true
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        _isAvailable == true
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isAvailable == true
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color:
                                          _isAvailable == true
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _isAvailable == true
                                            ? 'Kendaraan tersedia pada tanggal tersebut'
                                            : 'Kendaraan tidak tersedia. Pilih tanggal lain.',
                                        style: TextStyle(
                                          color:
                                              _isAvailable == true
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notes
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan (Opsional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Tambahkan catatan untuk booking ini',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment proof upload (optional)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Upload Bukti Pembayaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '*',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload bukti pembayaran wajib untuk melanjutkan booking.',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),

                            // UI untuk upload gambar (sama seperti sebelumnya)
                            if (_selectedImage != null)
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap:
                                            () => setState(
                                              () => _selectedImage = null,
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: double.infinity,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors
                                              .red
                                              .shade300, // Warna border merah untuk menunjukkan wajib
                                    ),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.cloud_upload,
                                        size: 40,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Upload Bukti Pembayaran (Wajib)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Booking button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isAvailable == true ? _processBooking : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: const Text(
                          'Booking Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }
}
