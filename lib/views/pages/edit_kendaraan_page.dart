import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';

class EditKendaraanPage extends StatefulWidget {
  final Vehicle vehicle;

  const EditKendaraanPage({super.key, required this.vehicle});

  @override
  State<EditKendaraanPage> createState() => _EditKendaraanPageState();
}

class _EditKendaraanPageState extends State<EditKendaraanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merkController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  late VehicleCategory _selectedCategory;

  final VehicleController _vehicleController = Get.find<VehicleController>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _merkController = TextEditingController(text: widget.vehicle.merk);
    _nameController = TextEditingController(text: widget.vehicle.name);
    _descriptionController = TextEditingController(
      text: widget.vehicle.description ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.vehicle.capacity.toString(),
    );
    _selectedCategory = widget.vehicle.category;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedVehicle = Vehicle(
          id: widget.vehicle.id,
          merk: _merkController.text,
          category: _selectedCategory,
          name: _nameController.text,
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
          capacity: int.parse(_capacityController.text),
          createdAt: widget.vehicle.createdAt,
          updatedAt: DateTime.now(),
        );

        final success = await _vehicleController.updateVehicle(updatedVehicle);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kendaraan berhasil diperbarui')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _vehicleController.errorMessage.value.isNotEmpty
                    ? _vehicleController.errorMessage.value
                    : 'Gagal menghapus kendaraan',
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
        title: const Text('Edit Master Kendaraan'),
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
              // ID display
              Text(
                'ID: ${widget.vehicle.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

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
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Timestamps display
              if (widget.vehicle.createdAt != null)
                Text(
                  'Dibuat pada: ${_formatDate(widget.vehicle.createdAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (widget.vehicle.updatedAt != null)
                Text(
                  'Terakhir diupdate: ${_formatDate(widget.vehicle.updatedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                          : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
