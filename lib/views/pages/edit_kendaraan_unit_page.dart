import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalkuy/controllers/vehicle_unit_controller.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/models/vehicle_unit_model.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:rentalkuy/services/vehicle_unit_service.dart';

class EditKendaraanUnitPage extends StatefulWidget {
  final int unitId;

  const EditKendaraanUnitPage({super.key, required this.unitId});

  @override
  State<EditKendaraanUnitPage> createState() => _EditKendaraanUnitPageState();
}

class _EditKendaraanUnitPageState extends State<EditKendaraanUnitPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _pricePerDayController;
  late TextEditingController _descriptionController;

  final VehicleUnitController _vehicleUnitController =
      Get.find<VehicleUnitController>();
  final VehicleController _vehicleController = Get.find<VehicleController>();

  VehicleUnit? _vehicleUnit;
  Vehicle? _selectedVehicle;
  List<Vehicle> _availableVehicles = [];
  Uint8List? _selectedImage;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _codeController = TextEditingController();
    _pricePerDayController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load vehicle unit
      final unit = await _vehicleUnitController.fetchVehicleUnitById(
        widget.unitId,
      );
      if (unit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unit kendaraan tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Load available vehicles for dropdown
      final vehicles = await _vehicleController.getVehicles();

      setState(() {
        _vehicleUnit = unit;
        _availableVehicles = vehicles;
        _selectedVehicle =
            vehicles.isNotEmpty
                ? vehicles.firstWhere(
                  (v) => v.id == unit.vehicleId,
                  orElse: () => vehicles.first,
                )
                : null;

        // Set form values
        _codeController.text = unit.code;
        _pricePerDayController.text = unit.pricePerDay.toString();
        if (unit.description != null) {
          _descriptionController.text = unit.description!;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _vehicleUnit != null &&
        _selectedVehicle != null) {
      setState(() => _isSubmitting = true);

      try {
        // First update vehicle unit data
        final updateSuccess = await _vehicleUnitController.updateVehicleUnit(
          id: _vehicleUnit!.id,
          code: _codeController.text,
          vehicleId: _selectedVehicle!.id!,
          pricePerDay: double.parse(_pricePerDayController.text),
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
        );

        // If update successful and image selected, upload the image
        if (updateSuccess && _selectedImage != null) {
          await _vehicleUnitController.uploadVehicleImage(
            _vehicleUnit!.id,
            _selectedImage!,
          );
        }

        if (updateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unit kendaraan berhasil diperbarui')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memperbarui unit: ${_vehicleUnitController.errorMessage.value}',
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
        setState(() => _isSubmitting = false);
      }
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
        title: const Text('Edit Unit Kendaraan'),
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
                      // Current vehicle image or placeholder
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            _vehicleUnit != null &&
                                    _vehicleUnit!.hasImage &&
                                    _selectedImage == null
                                ? Image.network(
                                  VehicleUnitService.getVehicleImageUrl(
                                    _vehicleUnit!.id,
                                  ),
                                  fit: BoxFit.cover,
                                  headers: {
                                    'Authorization':
                                        'Bearer ${_vehicleUnitController.token}',
                                  },
                                )
                                : _selectedImage != null
                                ? Image.memory(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                                : const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),

                      const SizedBox(height: 16),

                      // Button to change image
                      Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Ganti Gambar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Vehicle template selection
                      const Text(
                        'Jenis Kendaraan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<Vehicle>(
                        value: _selectedVehicle,
                        items:
                            _availableVehicles
                                .map(
                                  (vehicle) => DropdownMenuItem(
                                    value: vehicle,
                                    child: Text(
                                      '${vehicle.merk} ${vehicle.name} (${vehicle.categoryText})',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (vehicle) {
                          setState(() {
                            _selectedVehicle = vehicle;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Pilih jenis kendaraan';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Code field
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Kode Unit',
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
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Simpan Perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
