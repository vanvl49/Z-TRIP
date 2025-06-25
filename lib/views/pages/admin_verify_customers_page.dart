import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/admin_controller.dart';
import 'package:rentalkuy/models/user_model.dart';
import 'package:rentalkuy/services/admin_service.dart';

class AdminVerifyCustomersPage extends StatefulWidget {
  const AdminVerifyCustomersPage({super.key});

  @override
  State<AdminVerifyCustomersPage> createState() =>
      _AdminVerifyCustomersPageState();
}

class _AdminVerifyCustomersPageState extends State<AdminVerifyCustomersPage> {
  final AdminController _adminController = Get.find<AdminController>();
  bool _isLoading = true;
  List<User> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminController.getCustomersNeedingVerification();
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Customer'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingUsers,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingUsers.isEmpty
                ? const Center(
                  child: Text(
                    'Tidak ada customer yang menunggu verifikasi',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : ListView.builder(
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          backgroundImage: user.hasProfile
                              ? NetworkImage(
                                  AdminService.getCustomerProfileImageUrl(user.id),
                                  headers: {
                                    'Authorization': 'Bearer ${_adminController.getToken()}',
                                  },
                                )
                              : null,
                          child: !user.hasProfile
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CustomerVerificationDetailPage(
                                      user: user,
                                    ),
                              ),
                            ).then((verified) {
                              if (verified == true) {
                                _loadPendingUsers();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Periksa'),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class CustomerVerificationDetailPage extends StatefulWidget {
  final User user;

  const CustomerVerificationDetailPage({super.key, required this.user});

  @override
  State<CustomerVerificationDetailPage> createState() =>
      _CustomerVerificationDetailPageState();
}

class _CustomerVerificationDetailPageState
    extends State<CustomerVerificationDetailPage> {
  final AdminController _adminController = Get.find<AdminController>();
  bool _isVerifying = false;

  Future<void> _verifyCustomer() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await _adminController.verifyCustomer(widget.user.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer berhasil diverifikasi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memverifikasi: ${_adminController.errorMessage}',
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
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String ktpUrl = AdminService.getCustomerKtpImageUrl(widget.user.id);
    String simUrl = AdminService.getCustomerSimImageUrl(widget.user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Verifikasi'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer info card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('ID', widget.user.id.toString()),
                      _buildInfoRow('Nama', widget.user.name),
                      _buildInfoRow('Email', widget.user.email),
                      _buildInfoRow(
                        'KTP',
                        widget.user.hasKtp ? 'Terupload' : 'Belum upload',
                        valueColor:
                            widget.user.hasKtp ? Colors.green : Colors.red,
                      ),
                      _buildInfoRow(
                        'SIM',
                        widget.user.hasSim ? 'Terupload' : 'Belum upload',
                        valueColor:
                            widget.user.hasSim ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Check if customer has uploaded KTP
              if (widget.user.hasKtp) ...[
                const Text(
                  'Foto KTP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        ktpUrl,
                        fit: BoxFit.contain,
                        headers: {
                          'Authorization':
                              'Bearer ${_adminController.getToken()}',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Gagal memuat gambar KTP'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Show KTP in full screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FullscreenImageView(
                                imageUrl: ktpUrl,
                                title: 'KTP Customer',
                                token: _adminController.getToken() ?? '',
                              ),
                        ),
                      );
                    },
                    child: const Text('Lihat KTP Full Screen'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Check if customer has uploaded SIM
              if (widget.user.hasSim) ...[
                const Text(
                  'Foto SIM',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        simUrl,
                        fit: BoxFit.contain,
                        headers: {
                          'Authorization':
                              'Bearer ${_adminController.getToken()}',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Gagal memuat gambar SIM'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Show SIM in full screen
                      final token = _adminController.getToken();
                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token tidak ditemukan. Silakan login ulang.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FullscreenImageView(
                                imageUrl: simUrl,
                                title: 'SIM Customer',
                                token: token,
                              ),
                        ),
                      );
                    },
                    child: const Text('Lihat SIM Full Screen'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Verification button & requirements
              Card(
                elevation: 2,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Persyaratan Verifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Pastikan KTP dan SIM milik orang yang sama',
                      ),
                      const Text(
                        '• Pastikan data pada KTP terlihat dengan jelas',
                      ),
                      const Text('• SIM masih berlaku (tidak expired)'),
                      const Text('• Umur minimal 18 tahun'),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isVerifying ||
                                      !widget.user.hasKtp ||
                                      !widget.user.hasSim
                                  ? null
                                  : _verifyCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              _isVerifying
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('VERIFIKASI CUSTOMER'),
                        ),
                      ),

                      if (!widget.user.hasKtp || !widget.user.hasSim)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Customer harus mengupload KTP dan SIM terlebih dahulu',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Text(value, style: TextStyle(color: valueColor)),
        ],
      ),
    );
  }
}

class FullscreenImageView extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String token;

  const FullscreenImageView({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl,
            headers: {'Authorization': 'Bearer $token'},
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
