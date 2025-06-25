import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/profile_controller.dart';
import 'package:rentalkuy/views/pages/admin_verify_customers_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final authController = Get.find<AuthController>();
  final profileController = Get.put(ProfileController());
  final TextEditingController _nameController = TextEditingController();

  // Tambahkan state loading untuk upload
  bool _isUploadingProfile = false;
  bool _isUploadingKtp = false;
  bool _isUploadingSim = false;
  bool _isUpdatingName = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    // Tambahkan polling setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      profileController.loadProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authController.refreshUserProfile();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    await profileController.loadProfile();
    final user = profileController.userProfile.value;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  Future<void> _pickAndUploadImage(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    // Konversi ke JPG
    final bytes = await pickedFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final jpgBytes =
        decoded != null
            ? Uint8List.fromList(img.encodeJpg(decoded, quality: 85))
            : bytes;

    // Set loading state sesuai tipe
    setState(() {
      if (type == 'profile') _isUploadingProfile = true;
      if (type == 'ktp') _isUploadingKtp = true;
      if (type == 'sim') _isUploadingSim = true;
    });

    bool success = false;
    try {
      // Debug info
      print(
        '💡 Uploading $type with token: ${authController.getToken()?.substring(0, 10)}...',
      );
      print('💡 Image size: ${jpgBytes.length} bytes');

      if (type == 'profile') {
        success = await profileController.uploadProfileImage(jpgBytes);
      } else if (type == 'ktp') {
        success = await profileController.uploadKtpImage(jpgBytes);
      } else if (type == 'sim') {
        success = await profileController.uploadSimImage(jpgBytes);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload $type berhasil'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshProfile(); // Refresh setelah upload berhasil
      } else {
        _showError(profileController.errorMessage.value);
      }
    } catch (e) {
      print('❌ Upload error: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        // Cek apakah widget masih mounted
        setState(() {
          if (type == 'profile') _isUploadingProfile = false;
          if (type == 'ktp') _isUploadingKtp = false;
          if (type == 'sim') _isUploadingSim = false;
        });
      }
    }
  }

  Future<void> _editNameDialog() async {
    final user = profileController.userProfile.value;
    _nameController.text = user?.name ?? '';

    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            // Gunakan dialogContext, bukan context
            title: const Text('Edit Nama'),
            content: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              StatefulBuilder(
                // Gunakan StatefulBuilder daripada Obx di sini
                builder: (context, setDialogState) {
                  return ElevatedButton(
                    onPressed:
                        _isUpdatingName
                            ? null
                            : () async {
                              final newName = _nameController.text.trim();
                              if (newName.isNotEmpty) {
                                setDialogState(() => _isUpdatingName = true);
                                try {
                                  final success = await profileController
                                      .updateProfile(newName);
                                  if (success) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nama berhasil diupdate'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    await _refreshProfile();
                                  } else {
                                    _showError(
                                      profileController.errorMessage.value,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(
                                      () => _isUpdatingName = false,
                                    );
                                  }
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child:
                        _isUpdatingName
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Simpan'),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showError(String? msg) {
    final message =
        (msg == null || msg.isEmpty)
            ? 'Terjadi kesalahan. Silakan coba lagi.'
            : msg;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = authController.isAdmin;
    final isVerified = profileController.userProfile.value?.isVerified ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.verified_user),
              tooltip: 'Verifikasi User',
              onPressed: () {
                // Navigasi ke halaman verifikasi user (gunakan page yang sudah kamu buat)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            const AdminVerifyCustomersPage(), // <--- sudah benar
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: Obx(() {
          final isLoading = profileController.isLoading.value;
          final user = profileController.userProfile.value;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (user == null) {
            return const Center(child: Text('Tidak dapat memuat data profil'));
          }

          // Status dokumen
          final hasKtp = user.hasKtp;
          final hasSim = user.hasSim;
          final isVerified = user.isVerified;

          String statusText;
          Color statusColor;

          if (!hasKtp || !hasSim) {
            statusText = "Belum Upload Dokumen";
            statusColor = Colors.red;
          } else if (!isVerified) {
            statusText = "Menunggu Verifikasi";
            statusColor = Colors.orange;
          } else {
            statusText = "Terverifikasi";
            statusColor = Colors.green;
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Profile image with edit button
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _buildProfileImage(user.hasProfile),
                          // Edit foto profil hanya jika belum diverifikasi
                          if (!isAdmin && !isVerified)
                            Positioned(
                              right: 0,
                              child: CircleAvatar(
                                child: IconButton(
                                  icon:
                                      _isUploadingProfile
                                          ? CircularProgressIndicator()
                                          : Icon(Icons.camera_alt),
                                  onPressed:
                                      _isUploadingProfile
                                          ? null
                                          : () =>
                                              _pickAndUploadImage('profile'),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      // Edit nama hanya jika belum diverifikasi
                      if (!isAdmin && !isVerified)
                        ElevatedButton(
                          onPressed: _editNameDialog,
                          child: const Text('Edit Nama'),
                        ),
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Chip(
                            label: Text('Terverifikasi'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Status verifikasi
                      if (!isAdmin) // Hanya tampilkan untuk non-admin
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color:
                                  isVerified
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified_user
                                          : Icons.pending,
                                      color:
                                          isVerified
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    // Ganti teks status verifikasi
                                    Text(
                                      'Status Verifikasi: ${!hasKtp || !hasSim
                                          ? "Belum Upload Dokumen"
                                          : !isVerified
                                          ? "Menunggu Verifikasi"
                                          : "Terverifikasi"}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            !hasKtp || !hasSim
                                                ? Colors.red
                                                : !isVerified
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Dokumen Identitas',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // KTP Section
                                _buildDocumentSection(
                                  title: 'KTP',
                                  isUploaded: hasKtp,
                                  onUpload: () => _pickAndUploadImage('ktp'),
                                  isVerified: isVerified,
                                  isLoading: _isUploadingKtp,
                                  isAdmin: isAdmin,
                                ),
                                const SizedBox(height: 16),
                                // SIM Section
                                _buildDocumentSection(
                                  title: 'SIM',
                                  isUploaded: hasSim,
                                  onUpload: () => _pickAndUploadImage('sim'),
                                  isVerified: isVerified,
                                  isLoading: _isUploadingSim,
                                  isAdmin: isAdmin,
                                ),
                                const SizedBox(height: 16),
                                if ((!hasKtp || !hasSim) && !isAdmin)
                                  const Text(
                                    '❌ Mohon upload KTP dan SIM yang valid.\n Jika dalam 1x24 jam belum ada perubahan silakan periksa kembali data KTP dan SIM \n Pastikan Datanya valid',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if ((hasKtp && hasSim) &&
                                    !isVerified &&
                                    !isAdmin)
                                  const Text(
                                    'Dokumen Anda sedang dalam proses verifikasi oleh admin.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (isVerified)
                                  const Text(
                                    'Akun Anda sudah terverifikasi dan tidak dapat diubah lagi.',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Card(
                              color: Colors.orange.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 16),
                                    Icon(
                                      Icons.verified_user,
                                      color: Colors.orange,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Akun Admin',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.orange,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Anda login sebagai admin. Jangan Lupa Verifikasi User yang belum terverifikasi.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileImage(bool hasProfileImage) {
    if (hasProfileImage) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            profileController.getProfileImageUrl(),
            headers: {'Authorization': 'Bearer ${authController.getToken()}'},
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }
  }

  // Tambahkan parameter isAdmin pada _buildDocumentSection
  Widget _buildDocumentSection({
    required String title,
    required bool isUploaded,
    required VoidCallback onUpload,
    required bool isVerified,
    required bool isLoading,
    required bool isAdmin,
  }) {
    return Row(
      children: [
        Icon(
          isUploaded ? Icons.check_circle : Icons.highlight_off,
          color: isUploaded ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          // Tambahkan ini
          child: Text(title, overflow: TextOverflow.ellipsis),
        ),
        // Tombol upload hanya muncul jika belum diverifikasi dan bukan admin
        if (!isAdmin && !isVerified)
          ElevatedButton(
            onPressed: isLoading ? null : onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              disabledBackgroundColor: Colors.grey,
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(isUploaded ? 'Upload Ulang' : 'Upload'),
          ),
        if (isVerified)
          const Chip(
            label: Text('Terverifikasi'),
            backgroundColor: Colors.green,
            labelStyle: TextStyle(color: Colors.white),
          ),
        // Tombol lihat tetap muncul jika sudah upload
        if (title == 'KTP' && isUploaded)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(
                          profileController.getKtpImageUrl(),
                          headers: {
                            'Authorization':
                                'Bearer ${authController.getToken()}',
                          },
                        ),
                      ),
                    ),
              );
            },
            child: const Text('Lihat KTP'),
          ),
        if (title == 'SIM' && isUploaded)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(
                          profileController.getSimImageUrl(),
                          headers: {
                            'Authorization':
                                'Bearer ${authController.getToken()}',
                          },
                        ),
                      ),
                    ),
              );
            },
            child: const Text('Lihat SIM'),
          ),
      ],
    );
  }
}
