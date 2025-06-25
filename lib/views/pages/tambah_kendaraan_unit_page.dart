import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/controllers/vehicle_unit_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:image/image.dart' as img;

class TambahKendaraanUnitPage extends StatefulWidget {
  const TambahKendaraanUnitPage({super.key});

  @override
  State<TambahKendaraanUnitPage> createState() =>
      _TambahKendaraanUnitPageState();
}

class _TambahKendaraanUnitPageState extends State<TambahKendaraanUnitPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final VehicleController _vehicleController = Get.find<VehicleController>();
  final VehicleUnitController _vehicleUnitController =
      Get.find<VehicleUnitController>();

  Uint8List? _selectedImage;
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  List<Vehicle> _availableVehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      await _vehicleController.fetchAllVehicles(); // Selalu fetch terbaru
      _availableVehicles = _vehicleController.vehicles.toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading vehicles: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
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

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();

      // Konversi universal ke JPEG
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final jpegBytes = img.encodeJpg(decoded, quality: 85);
        setState(() {
          _selectedImage = Uint8List.fromList(jpegBytes);
        });
      } else {
        // Jika gagal decode, fallback ke bytes asli
        setState(() {
          _selectedImage = bytes;
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedVehicle!.id != null) {
      setState(() => _isLoading = true);

      try {
        final success = await _vehicleUnitController.addVehicleUnit(
          code: _codeController.text,
          vehicleId: _selectedVehicle!.id!,
          pricePerDay: double.parse(_pricePerDayController.text),
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
          imageBytes: _selectedImage,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unit kendaraan berhasil ditambahkan'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          // Error dari controller
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menambahkan unit kendaraan: ${_vehicleUnitController.errorMessage.value}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Tampilkan pesan error dari exception
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (_selectedVehicle == null || _selectedVehicle!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih template kendaraan terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pricePerDayController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Unit Kendaraan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Template Kendaraan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Vehicle template selection
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Vehicle>(
                            isExpanded: true,
                            hint: const Text('Pilih kendaraan'),
                            value: _selectedVehicle,
                            items:
                                _availableVehicles.isEmpty
                                    ? []
                                    : _availableVehicles
                                        .map(
                                          (vehicle) => DropdownMenuItem(
                                            value: vehicle,
                                            child: Text(
                                              '${vehicle.merk} ${vehicle.name} (${vehicle.categoryText})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                            onChanged:
                                _availableVehicles.isEmpty
                                    ? null
                                    : (Vehicle? value) {
                                      setState(() {
                                        _selectedVehicle = value;
                                      });
                                    },
                          ),
                        ),
                      ),

                      if (_availableVehicles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Belum ada template kendaraan. Tambahkan master kendaraan terlebih dahulu.',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Code field
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Kode Unit',
                          hintText: 'Contoh: SZK-001',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kode unit tidak boleh kosong';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Price field
                      TextFormField(
                        controller: _pricePerDayController,
                        decoration: const InputDecoration(
                          labelText: 'Harga per Hari (Rp)',
                          hintText: 'Contoh: 150000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          try {
                            final price = double.parse(value);
                            if (price <= 0) {
                              return 'Harga harus lebih dari 0';
                            }
                          } catch (e) {
                            return 'Harga harus berupa angka';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          hintText: 'Kondisi kendaraan, fitur khusus, dll.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Image upload
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child:
                              _selectedImage != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                  : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tambahkan Gambar Kendaraan (Opsional)',
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Simpan Unit Kendaraan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
