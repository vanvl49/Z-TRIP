import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';

class TambahKendaraanPage extends StatefulWidget {
  const TambahKendaraanPage({super.key});

  @override
  State<TambahKendaraanPage> createState() => _TambahKendaraanPageState();
}

class _TambahKendaraanPageState extends State<TambahKendaraanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  final VehicleController _vehicleController = Get.find<VehicleController>();

  VehicleCategory _selectedCategory = VehicleCategory.mobil;
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newVehicle = Vehicle(
          id: 0, // ID akan di-set oleh server
          merk: _merkController.text,
          category: _selectedCategory,
          name: _nameController.text,
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
          capacity: int.parse(_capacityController.text),
          createdAt: null,
          updatedAt: null,
        );

        final success = await _vehicleController.addVehicle(newVehicle);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kendaraan berhasil ditambahkan')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menambahkan kendaraan: ${_vehicleController.errorMessage.value}',
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

  @override
  void dispose() {
    _merkController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Master Kendaraan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category selection
              const Text(
                'Kategori Kendaraan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<VehicleCategory>(
                      title: const Text('Mobil'),
                      value: VehicleCategory.mobil,
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<VehicleCategory>(
                      title: const Text('Motor'),
                      value: VehicleCategory.motor,
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Merk field
              TextFormField(
                controller: _merkController,
                decoration: const InputDecoration(
                  labelText: 'Merk',
                  hintText: 'Contoh: Honda, Toyota, dll',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Merk tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kendaraan',
                  hintText: 'Contoh: Civic, Avanza, dll',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kendaraan tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Capacity field
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Kapasitas (orang)',
                  hintText: 'Contoh: 2, 4, 6, dll',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kapasitas tidak boleh kosong';
                  }
                  try {
                    final capacity = int.parse(value);
                    if (capacity <= 0) {
                      return 'Kapasitas harus lebih dari 0';
                    }
                  } catch (e) {
                    return 'Kapasitas harus berupa angka';
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
                  hintText: 'Keterangan tambahan tentang kendaraan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                          : const Text('Simpan Kendaraan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
