import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/admin_controller.dart';
import 'package:rentalkuy/models/user_model.dart';
import 'package:rentalkuy/services/admin_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final int userId;

  const CustomerDetailPage({super.key, required this.userId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final AdminController _adminController = Get.find<AdminController>();
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final token = _adminController.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final user = await AdminService.getCustomerById(token, widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyUser() async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await _adminController.verifyCustomer(_user!.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil diverifikasi'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memverifikasi pengguna: ${_adminController.errorMessage.value}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(child: Text('Pengguna tidak ditemukan'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.orange.shade100,
                                backgroundImage:
                                    _user!.hasProfile
                                        ? NetworkImage(
                                          AdminService.getCustomerProfileImageUrl(
                                            _user!.id,
                                          ),
                                          headers: {
                                            'Authorization':
                                                'Bearer ${_adminController.getToken()}',
                                          },
                                        )
                                        : null,
                                child:
                                    !_user!.hasProfile
                                        ? Text(
                                          _user!.name.isNotEmpty
                                              ? _user!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            color: Colors.orange,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    _user!.email,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          _user!.isVerified
                                              ? 'Terverifikasi'
                                              : 'Belum Verifikasi',
                                        ),
                                        backgroundColor:
                                            _user!.isVerified
                                                ? Colors.green
                                                : Colors.red,
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          _user!.isAdmin ? 'Admin' : 'Customer',
                                        ),
                                        backgroundColor:
                                            _user!.isAdmin
                                                ? Colors.blue
                                                : Colors.orange,
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Document verification section
                    const Text(
                      'Dokumen Verifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KTP Document
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          _user!.hasKtp ? Icons.check_circle : Icons.cancel,
                          color: _user!.hasKtp ? Colors.green : Colors.red,
                        ),
                        title: const Text('KTP'),
                        subtitle: Text(
                          _user!.hasKtp ? 'Sudah diupload' : 'Belum diupload',
                        ),
                        trailing:
                            _user!.hasKtp
                                ? TextButton(
                                  onPressed: () {
                                    final token = _adminController.getToken();
                                    if (token == null) return;
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => Dialog(
                                            child: InteractiveViewer(
                                              child: Image.network(
                                                AdminService.getCustomerKtpImageUrl(
                                                  _user!.id,
                                                ),
                                                headers: {
                                                  'Authorization':
                                                      'Bearer $token',
                                                },
                                                errorBuilder:
                                                    (c, e, s) => const Center(
                                                      child: Text(
                                                        'Gagal memuat gambar',
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                    );
                                  },
                                  child: const Text('Lihat'),
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SIM Document
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          _user!.hasSim ? Icons.check_circle : Icons.cancel,
                          color: _user!.hasSim ? Colors.green : Colors.red,
                        ),
                        title: const Text('SIM'),
                        subtitle: Text(
                          _user!.hasSim ? 'Sudah diupload' : 'Belum diupload',
                        ),
                        trailing:
                            _user!.hasSim
                                ? TextButton(
                                  onPressed: () {
                                    final token = _adminController.getToken();
                                    if (token == null) return;
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => Dialog(
                                            child: InteractiveViewer(
                                              child: Image.network(
                                                AdminService.getCustomerSimImageUrl(
                                                  _user!.id,
                                                ),
                                                headers: {
                                                  'Authorization':
                                                      'Bearer $token',
                                                },
                                                errorBuilder:
                                                    (c, e, s) => const Center(
                                                      child: Text(
                                                        'Gagal memuat gambar',
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                    );
                                  },
                                  child: const Text('Lihat'),
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification button
                    if (!_user!.isVerified)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('Verifikasi Customer'),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
