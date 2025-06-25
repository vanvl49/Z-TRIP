import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/controllers/vehicle_unit_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:rentalkuy/models/vehicle_unit_model.dart';
import 'package:rentalkuy/services/vehicle_unit_service.dart';
import 'package:rentalkuy/views/pages/edit_kendaraan_unit_page.dart';
import 'package:rentalkuy/views/pages/booking_page.dart';

class DetailKendaraanUnitPage extends StatefulWidget {
  final int unitId;

  const DetailKendaraanUnitPage({super.key, required this.unitId});

  @override
  State<DetailKendaraanUnitPage> createState() =>
      _DetailKendaraanUnitPageState();
}

class _DetailKendaraanUnitPageState extends State<DetailKendaraanUnitPage> {
  final VehicleUnitController _vehicleUnitController =
      Get.find<VehicleUnitController>();
  final VehicleController _vehicleController = Get.find<VehicleController>();
  final AuthController _authController = Get.find<AuthController>();

  bool _isLoading = true;
  String _errorMessage = '';
  VehicleUnit? _vehicleUnit;
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final unit = await _vehicleUnitController.fetchVehicleUnitById(
        widget.unitId,
      );
      if (unit != null) {
        final vehicle = await _vehicleController.fetchVehicleById(
          unit.vehicleId,
        );
        setState(() {
          _vehicleUnit = unit;
          _vehicle = vehicle;
        });
      } else {
        setState(() {
          _errorMessage = 'Unit kendaraan tidak ditemukan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Anda yakin ingin menghapus unit kendaraan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true && _vehicleUnit != null) {
      setState(() => _isLoading = true);

      try {
        final success = await _vehicleUnitController.deleteVehicleUnit(
          _vehicleUnit!.id,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unit kendaraan berhasil dihapus')),
          );
          Navigator.pop(context, true); // Return true to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus: ${_vehicleUnitController.errorMessage.value}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToBooking() {
    if (_vehicleUnit != null && _vehicle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  BookingPage(vehicleUnit: _vehicleUnit!, vehicle: _vehicle!),
        ),
      );
    }
  }

  void _navigateToEdit() {
    if (_vehicleUnit != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditKendaraanUnitPage(unitId: _vehicleUnit!.id),
        ),
      ).then((result) {
        if (result == true) {
          _loadData(); // Refresh data
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Unit Kendaraan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),

          // Show edit and delete buttons only for admin
          if (_authController.isAdmin && _vehicleUnit != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Unit',
              onPressed: _navigateToEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Unit',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          (!_authController.isAdmin && _vehicleUnit != null && _vehicle != null)
              ? FloatingActionButton.extended(
                onPressed: _navigateToBooking,
                label: const Text('Booking Sekarang'),
                icon: const Icon(Icons.calendar_today),
                backgroundColor: Colors.orange,
              )
              : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicleUnit == null || _vehicle == null) {
      return Center(
        child: Text(
          _errorMessage.isNotEmpty ? _errorMessage : 'Tidak ada data',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child:
                  _vehicleUnit!.hasImage
                      ? Image.network(
                        VehicleUnitService.getVehicleImageUrl(_vehicleUnit!.id),
                        fit: BoxFit.cover,
                        headers: {
                          'Authorization':
                              'Bearer ${_authController.getToken()}',
                        },
                      )
                      : Center(
                        child: Icon(
                          _vehicle!.category == VehicleCategory.motor
                              ? Icons.motorcycle
                              : Icons.directions_car,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
            ),

            // Vehicle details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and code
                  Text(
                    '${_vehicle!.merk} ${_vehicle!.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kode Unit: ${_vehicleUnit!.code}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rp${_vehicleUnit!.pricePerDay.toStringAsFixed(0)}/hari',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle info
                  const Text(
                    'Informasi Kendaraan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoTile('Kategori', _vehicle!.categoryText),
                  _infoTile('Merk', _vehicle!.merk),
                  _infoTile('Kapasitas', '${_vehicle!.capacity} orang'),
                  if (_vehicle!.description != null &&
                      _vehicle!.description!.isNotEmpty)
                    _infoTile('Deskripsi Kendaraan', _vehicle!.description!),
                  const SizedBox(height: 16),

                  // Unit info
                  const Text(
                    'Informasi Unit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_vehicleUnit!.description != null &&
                      _vehicleUnit!.description!.isNotEmpty)
                    _infoTile('Deskripsi Unit', _vehicleUnit!.description!),
                  _infoTile(
                    'Dibuat pada',
                    _vehicleUnit!.createdAt != null
                        ? _formatDate(_vehicleUnit!.createdAt!)
                        : '-',
                  ),
                  _infoTile(
                    'Terakhir diupdate',
                    _vehicleUnit!.updatedAt != null
                        ? _formatDate(_vehicleUnit!.updatedAt!)
                        : '-',
                  ),
                  const SizedBox(height: 16),

                  // Rental terms (dummy data, can be customized)
                  const Text(
                    'Syarat & Ketentuan Sewa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Membawa KTP asli'),
                    dense: true,
                  ),
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Membawa SIM yang masih berlaku'),
                    dense: true,
                  ),
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Wajib meninggalkan jaminan'),
                    dense: true,
                  ),
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Pengembalian tepat waktu'),
                    dense: true,
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
