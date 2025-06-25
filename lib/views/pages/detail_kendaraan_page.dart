import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'edit_kendaraan_page.dart';

class DetailKendaraanPage extends StatelessWidget {
  final Vehicle vehicle;

  const DetailKendaraanPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final VehicleController vehicleController = Get.find<VehicleController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Kendaraan'),
        backgroundColor: const Color(0xFFFB923C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (authController.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Template Kendaraan',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditKendaraanPage(vehicle: vehicle),
                  ),
                );
                if (result == true) {
                  Navigator.pop(context, true); // Refresh daftar kendaraan
                }
              },
            ),
          if (authController.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Kendaraan',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Konfirmasi Hapus'),
                        content: const Text(
                          'Jika kendaraan ini atau unit kendaraannya pernah di-booking, penghapusan tidak diizinkan. Lanjutkan?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  final result = await vehicleController.deleteVehicle(
                    vehicle.id!,
                  );
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kendaraan berhasil dihapus'),
                      ),
                    );
                    Navigator.pop(context, true); // Refresh daftar kendaraan
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vehicleController.errorMessage.value.isNotEmpty
                              ? vehicleController.errorMessage.value
                              : 'Gagal menghapus kendaraan',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          // Foto kendaraan - placeholder
          Container(
            margin: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 8,
            ), // Kurangi bottom margin
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://via.placeholder.com/360x207.png?text=No+Image',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Nama & Info
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 0,
            ), // Hilangkan vertical padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Tidak ada pricePerDay di master, tampilkan info
                const Text(
                  'Lihat unit kendaraan untuk harga sewa',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Deskripsi
                if (vehicle.description != null &&
                    vehicle.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      vehicle.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                // Info kendaraan
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Merk: ${vehicle.merk}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Kategori: ${vehicle.categoryText}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Kapasitas: ${vehicle.capacity} orang'),
                  ],
                ),
                const SizedBox(height: 16),
                // Syarat & Ketentuan
                const Text(
                  'Syarat & Ketentuan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  '- Membawa KTP asli\n- Usia minimal 18 tahun\n- Tidak boleh digunakan untuk balapan\n- Pengembalian tepat waktu',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                // Tombol Lihat Unit Tersedia (untuk customer)
                if (!authController.isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFABF1D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (!authController.isVerified ||
                            !authController.hasKtp ||
                            !authController.hasSim) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Anda harus upload KTP & SIM dan diverifikasi admin sebelum booking!',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        // TODO: Navigasi ke daftar unit kendaraan dari vehicle ini
                        // Misal: Navigator.push ke halaman list unit dengan filter vehicleId
                      },
                      child: const Text(
                        'Lihat Unit Tersedia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
