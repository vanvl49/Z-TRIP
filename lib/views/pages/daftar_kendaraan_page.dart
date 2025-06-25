import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rentalkuy/controllers/vehicle_unit_controller.dart';
import 'package:rentalkuy/controllers/auth_controller.dart';
import 'package:rentalkuy/controllers/vehicle_controller.dart';
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:rentalkuy/models/vehicle_unit_model.dart';
import 'package:rentalkuy/services/base_service.dart';
import 'package:rentalkuy/services/vehicle_unit_service.dart';
import 'package:rentalkuy/views/pages/detail_kendaraan_unit_page.dart';
import 'package:rentalkuy/views/pages/tambah_kendaraan_page.dart';
import 'package:rentalkuy/views/pages/tambah_kendaraan_unit_page.dart';
import 'package:rentalkuy/views/pages/edit_kendaraan_unit_page.dart';
import 'package:rentalkuy/views/pages/edit_kendaraan_page.dart';
import 'package:rentalkuy/views/pages/detail_kendaraan_page.dart';

class DaftarKendaraanSewaView extends StatefulWidget {
  const DaftarKendaraanSewaView({super.key});

  @override
  State<DaftarKendaraanSewaView> createState() =>
      _DaftarKendaraanSewaViewState();
}

class _DaftarKendaraanSewaViewState extends State<DaftarKendaraanSewaView> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kendaraan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _authController.isAdmin
              ? const AdminVehicleTabView()
              : const CustomerVehicleUnitView(),
    );
  }
}

/// Admin view with tabs for Unit and Master vehicles
class AdminVehicleTabView extends StatefulWidget {
  const AdminVehicleTabView({super.key});

  @override
  State<AdminVehicleTabView> createState() => _AdminVehicleTabViewState();
}

class _AdminVehicleTabViewState extends State<AdminVehicleTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          tabs: const [
            Tab(text: 'Unit Kendaraan'),
            Tab(text: 'Master Kendaraan'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [VehicleUnitAdminView(), VehicleAdminView()],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Customer view - only shows available units with Motor/Mobil tabs
class CustomerVehicleUnitView extends StatefulWidget {
  const CustomerVehicleUnitView({super.key});

  @override
  State<CustomerVehicleUnitView> createState() =>
      _CustomerVehicleUnitViewState();
}

class _CustomerVehicleUnitViewState extends State<CustomerVehicleUnitView>
    with SingleTickerProviderStateMixin {
  final VehicleUnitController _vehicleUnitController =
      Get.find<VehicleUnitController>();
  final VehicleController _vehicleController = Get.find<VehicleController>();
  final AuthController _authController = Get.find<AuthController>();
  late TabController _tabController;

  // Filters for vehicle units
  String? _filterMerk;
  int? _filterKapasitas;
  double? _filterPriceMin;
  double? _filterPriceMax;
  String? _searchNama;
  String _selectedCategory = "motor"; // Default to motor on first load
  final TextEditingController _searchController = TextEditingController();

  // Map to store vehicle templates by ID for quick lookup
  final Map<int, Vehicle> _vehiclesById = {};
  final RxBool _isLoadingVehicles = false.obs;

  @override
  void initState() {
    super.initState();

    // Tambahkan ini agar status verifikasi user selalu update
    _authController.refreshUserProfile();

    // Tab controller setup
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _tabController.index == 0 ? 'motor' : 'mobil';
        });
      }
    });

    // Load vehicles immediately
    _loadVehiclesAndUnits();
  }

  Future<void> _loadVehiclesAndUnits() async {
    _isLoadingVehicles.value = true;

    try {
      final token = _authController.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Get all vehicle templates
      final vehicles = await _vehicleController.getVehicles().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Waktu permintaan habis'),
      );

      // Bersihkan map lookup
      _vehiclesById.clear();
      for (var vehicle in vehicles) {
        if (vehicle.id != null) {
          _vehiclesById[vehicle.id!] = vehicle;
        }
      }

      // Load all vehicle units
      await _vehicleUnitController.getVehicleUnits().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Waktu permintaan habis'),
      );

      if (BaseService.debugMode) {
        print("Loaded ${vehicles.length} vehicle templates");
        print(
          "Loaded ${_vehicleUnitController.vehicleUnits.length} vehicle units",
        );
      }
    } catch (e) {
      // Show informative error message
      String errorMessage = 'Error saat memuat data';

      if (e.toString().contains("500")) {
        errorMessage = 'Server error (kode 500). Silakan coba lagi nanti.';
      } else if (e.toString().contains("timeout")) {
        errorMessage = 'Koneksi timeout. Periksa koneksi internet Anda.';
      } else if (e.toString().contains("Failed host lookup")) {
        errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }

      print("Error loading vehicles/units: $e");
    } finally {
      _isLoadingVehicles.value = false;
    }
  }

  // Filter units based on the selected category and other filters
  List<VehicleUnit> _getFilteredUnits() {
    return _vehicleUnitController.vehicleUnits.where((unit) {
      // Skip units where we don't have vehicle info
      if (!_vehiclesById.containsKey(unit.vehicleId)) {
        return false;
      }

      // Get the associated vehicle to check its category
      final vehicle = _vehiclesById[unit.vehicleId]!;

      // Check if vehicle category matches the selected tab
      bool categoryMatches = false;
      if (_selectedCategory == 'motor') {
        categoryMatches = vehicle.category == VehicleCategory.motor;
      } else {
        categoryMatches = vehicle.category == VehicleCategory.mobil;
      }
      if (!categoryMatches) return false;

      // Apply additional filters
      if (_filterMerk != null &&
          !vehicle.merk.toLowerCase().contains(_filterMerk!.toLowerCase())) {
        return false;
      }

      if (_filterKapasitas != null && vehicle.capacity < _filterKapasitas!) {
        return false;
      }

      if (_filterPriceMin != null && unit.pricePerDay < _filterPriceMin!) {
        return false;
      }

      if (_filterPriceMax != null && unit.pricePerDay > _filterPriceMax!) {
        return false;
      }

      if (_searchNama != null &&
          !vehicle.name.toLowerCase().contains(_searchNama!.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterDialog() async {
    final merkController = TextEditingController(text: _filterMerk ?? '');
    final kapasitasController = TextEditingController(
      text: _filterKapasitas?.toString() ?? '',
    );
    final priceMinController = TextEditingController(
      text: _filterPriceMin?.toString() ?? '',
    );
    final priceMaxController = TextEditingController(
      text: _filterPriceMax?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Kendaraan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merkController,
                  decoration: const InputDecoration(
                    labelText: 'Merk',
                    hintText: 'e.g., Honda, Yamaha',
                  ),
                ),
                TextField(
                  controller: kapasitasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kapasitas Minimal',
                    hintText: 'e.g., 2, 4',
                  ),
                ),
                TextField(
                  controller: priceMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Minimal',
                    hintText: 'e.g., 50000',
                  ),
                ),
                TextField(
                  controller: priceMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Maksimal',
                    hintText: 'e.g., 200000',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterMerk = null;
                  _filterKapasitas = null;
                  _filterPriceMin = null;
                  _filterPriceMax = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterMerk =
                      merkController.text.isEmpty ? null : merkController.text;
                  _filterKapasitas =
                      kapasitasController.text.isEmpty
                          ? null
                          : int.tryParse(kapasitasController.text);
                  _filterPriceMin =
                      priceMinController.text.isEmpty
                          ? null
                          : double.tryParse(priceMinController.text);
                  _filterPriceMax =
                      priceMaxController.text.isEmpty
                          ? null
                          : double.tryParse(priceMaxController.text);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog for admin to add either vehicle template or vehicle unit
  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('Tambah Jenis Kendaraan'),
                subtitle: const Text('Buat template master kendaraan baru'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TambahKendaraanPage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadVehiclesAndUnits();
                    }
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.car_rental),
                title: const Text('Tambah Unit Kendaraan'),
                subtitle: const Text(
                  'Tambahkan unit pada jenis kendaraan yang sudah ada',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TambahKendaraanUnitPage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadVehiclesAndUnits();
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Kendaraan Tersedia'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Motor'), Tab(text: 'Mobil')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama kendaraan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchNama = null;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchNama = value.isEmpty ? null : value;
                });
              },
            ),
          ),

          // List of vehicles
          Expanded(
            child: Obx(() {
              if (_isLoadingVehicles.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredUnits = _getFilteredUnits();

              if (filteredUnits.isEmpty) {
                return const Center(
                  child: Text('Tidak ada kendaraan tersedia'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: filteredUnits.length,
                itemBuilder: (context, index) {
                  final unit = filteredUnits[index];
                  final vehicle = _vehiclesById[unit.vehicleId]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading:
                          unit.hasImage
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  VehicleUnitService.getVehicleImageUrl(
                                    unit.id,
                                  ),
                                  headers: {
                                    'Authorization':
                                        'Bearer ${_authController.getToken()}',
                                  },
                                ),
                              )
                              : CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Icon(
                                  vehicle.category == VehicleCategory.motor
                                      ? Icons.motorcycle
                                      : Icons.directions_car,
                                  color: Colors.orange,
                                ),
                              ),
                      title: Text(
                        '${vehicle.merk} ${vehicle.name} (${unit.code})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rp${unit.pricePerDay.toStringAsFixed(0)}/hari'),
                          Text('Kapasitas: ${vehicle.capacity} orang'),
                          if (unit.description != null &&
                              unit.description!.isNotEmpty)
                            Text(
                              unit.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DetailKendaraanUnitPage(unitId: unit.id),
                          ),
                        ).then((_) => _loadVehiclesAndUnits());
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

/// Admin view - Unit Kendaraan tab
class VehicleUnitAdminView extends StatefulWidget {
  const VehicleUnitAdminView({super.key});

  @override
  State<VehicleUnitAdminView> createState() => _VehicleUnitAdminViewState();
}

class _VehicleUnitAdminViewState extends State<VehicleUnitAdminView>
    with SingleTickerProviderStateMixin {
  final VehicleUnitController _vehicleUnitController =
      Get.find<VehicleUnitController>();
  final VehicleController _vehicleController = Get.find<VehicleController>();
  final AuthController _authController = Get.find<AuthController>();
  late TabController _tabController;

  String _selectedCategory = "motor"; // Default to motor on first load
  final Map<int, Vehicle> _vehiclesById = {};
  final RxBool _isLoadingVehicles = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _tabController.index == 0 ? 'motor' : 'mobil';
        });
      }
    });

    _loadVehiclesAndUnits();
  }

  Future<void> _loadVehiclesAndUnits() async {
    _isLoadingVehicles.value = true;

    try {
      final token = _authController.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Get all vehicle templates
      final vehicles = await _vehicleController.getVehicles().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Waktu permintaan habis'),
      );

      // Bersihkan map lookup
      _vehiclesById.clear();
      for (var vehicle in vehicles) {
        if (vehicle.id != null) {
          _vehiclesById[vehicle.id!] = vehicle;
        }
      }

      // Load all vehicle units
      await _vehicleUnitController.getVehicleUnits().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Waktu permintaan habis'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoadingVehicles.value = false;
    }
  }

  // Filter units based on the selected category
  List<VehicleUnit> _getFilteredUnits() {
    return _vehicleUnitController.vehicleUnits.where((unit) {
      if (!_vehiclesById.containsKey(unit.vehicleId)) return false;

      final vehicle = _vehiclesById[unit.vehicleId]!;

      if (_selectedCategory == 'motor') {
        return vehicle.category == VehicleCategory.motor;
      } else {
        return vehicle.category == VehicleCategory.mobil;
      }
    }).toList();
  }

  void _showAddUnitDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahKendaraanUnitPage()),
    ).then((value) {
      if (value == true) {
        // Setelah tambah unit, refresh list unit kendaraan
        setState(() {
          _vehicleUnitController.fetchAllVehicleUnits();
        });
      }
    });
  }

  // Check if unit has bookings before deleting
  Future<bool> _checkHasBookings(int unitId) async {
    final token = _authController.getToken();
    if (token == null) return true; // Default true for safety

    try {
      return await VehicleUnitService.hasVehicleUnitBookings(token, unitId);
    } catch (e) {
      print("Error checking bookings: $e");
      return true; // Assume it has bookings if error
    }
  }

  // Handle edit/delete actions for vehicle units
  void _handleUnitAction(String value, VehicleUnit unit) async {
    if (value == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditKendaraanUnitPage(unitId: unit.id),
        ),
      ).then((result) {
        if (result == true) {
          _loadVehiclesAndUnits();
        }
      });
    } else if (value == 'delete') {
      final hasBookings = await _checkHasBookings(unit.id);
      if (hasBookings) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat menghapus unit yang memiliki booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Konfirmasi'),
                content: const Text(
                  'Yakin ingin menghapus unit kendaraan ini?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
        );

        if (confirmed == true) {
          final result = await _vehicleUnitController.deleteVehicleUnit(
            unit.id,
          );
          if (result) {
            _loadVehiclesAndUnits();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for Motor/Mobil
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          tabs: const [Tab(text: 'Motor'), Tab(text: 'Mobil')],
        ),

        // Add button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddUnitDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Unit Kendaraan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // List of vehicle units
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Motor tab
              Obx(() {
                if (_isLoadingVehicles.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredUnits = _getFilteredUnits();

                if (filteredUnits.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada unit kendaraan tersedia'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final vehicle = _vehiclesById[unit.vehicleId]!;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading:
                            unit.hasImage
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    VehicleUnitService.getVehicleImageUrl(
                                      unit.id,
                                    ),
                                    headers: {
                                      'Authorization':
                                          'Bearer ${_authController.getToken()}',
                                    },
                                  ),
                                )
                                : CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(
                                    vehicle.category == VehicleCategory.motor
                                        ? Icons.motorcycle
                                        : Icons.directions_car,
                                    color: Colors.orange,
                                  ),
                                ),
                        title: Text(
                          '${vehicle.merk} ${vehicle.name} (${unit.code})',
                        ),
                        subtitle: Text(
                          'Rp${unit.pricePerDay.toStringAsFixed(0)}/hari',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _handleUnitAction('edit', unit),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => _handleUnitAction('delete', unit),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      DetailKendaraanUnitPage(unitId: unit.id),
                            ),
                          ).then((_) => _loadVehiclesAndUnits());
                        },
                      ),
                    );
                  },
                );
              }),

              // Mobil tab (identical except filter is different)
              Obx(() {
                if (_isLoadingVehicles.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredUnits = _getFilteredUnits();

                if (filteredUnits.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada unit kendaraan tersedia'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final vehicle = _vehiclesById[unit.vehicleId]!;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading:
                            unit.hasImage
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    VehicleUnitService.getVehicleImageUrl(
                                      unit.id,
                                    ),
                                    headers: {
                                      'Authorization':
                                          'Bearer ${_authController.getToken()}',
                                    },
                                  ),
                                )
                                : CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(
                                    vehicle.category == VehicleCategory.motor
                                        ? Icons.motorcycle
                                        : Icons.directions_car,
                                    color: Colors.orange,
                                  ),
                                ),
                        title: Text(
                          '${vehicle.merk} ${vehicle.name} (${unit.code})',
                        ),
                        subtitle: Text(
                          'Rp${unit.pricePerDay.toStringAsFixed(0)}/hari',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _handleUnitAction('edit', unit),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => _handleUnitAction('delete', unit),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      DetailKendaraanUnitPage(unitId: unit.id),
                            ),
                          ).then((_) => _loadVehiclesAndUnits());
                        },
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Admin view - Master Kendaraan tab
class VehicleAdminView extends StatefulWidget {
  const VehicleAdminView({super.key});

  @override
  State<VehicleAdminView> createState() => _VehicleAdminViewState();
}

class _VehicleAdminViewState extends State<VehicleAdminView>
    with SingleTickerProviderStateMixin {
  final VehicleController _vehicleController = Get.find<VehicleController>();
  final AuthController _authController = Get.find<AuthController>();
  final RxBool _isLoading = false.obs;
  late TabController _tabController;
  String _selectedCategory = "motor";
  String? _searchNama;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _tabController.index == 0 ? 'motor' : 'mobil';
        });
      }
    });
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    _isLoading.value = true;
    try {
      await _vehicleController.getVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  List<Vehicle> _getFilteredVehicles() {
    return _vehicleController.vehicles.where((vehicle) {
      final isMotor = vehicle.category == VehicleCategory.motor;
      final isMobil = vehicle.category == VehicleCategory.mobil;
      if (_selectedCategory == 'motor' && !isMotor) return false;
      if (_selectedCategory == 'mobil' && !isMobil) return false;
      if (_searchNama != null &&
          !('${vehicle.merk} ${vehicle.name}'.toLowerCase()).contains(
            _searchNama!.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showAddVehicleDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahKendaraanPage()),
    ).then((value) {
      if (value == true) {
        _loadVehicles();
      }
    });
  }

  Future<void> _handleVehicleAction(String action, Vehicle vehicle) async {
    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditKendaraanPage(vehicle: vehicle)),
      ).then((value) {
        if (value == true) {
          _loadVehicles();
        }
      });
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text(
                'Yakin ingin menghapus master kendaraan ini? Semua unit terkait juga akan terhapus.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        try {
          if (vehicle.id == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID kendaraan tidak valid.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          final result = await _vehicleController.deleteVehicle(vehicle.id!);
          if (result) {
            _loadVehicles();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menghapus kendaraan: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else if (action == 'view') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailKendaraanPage(vehicle: vehicle),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for Motor/Mobil
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          tabs: const [Tab(text: 'Motor'), Tab(text: 'Mobil')],
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama/merk kendaraan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchNama = null;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchNama = value.isEmpty ? null : value;
              });
            },
          ),
        ),
        // Add button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _showAddVehicleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Master Kendaraan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        // List of vehicles
        Expanded(
          child: Obx(() {
            if (_isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = _getFilteredVehicles();

            if (vehicles.isEmpty) {
              return const Center(
                child: Text('Tidak ada master kendaraan tersedia'),
              );
            }

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(
                        vehicle.category == VehicleCategory.motor
                            ? Icons.motorcycle
                            : Icons.directions_car,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text('${vehicle.merk} ${vehicle.name}'),
                    subtitle: Text(
                      'Kapasitas: ${vehicle.capacity} orang, Kategori: ${vehicle.categoryText}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              () => _handleVehicleAction('edit', vehicle),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () => _handleVehicleAction('delete', vehicle),
                        ),
                      ],
                    ),
                    onTap: () => _handleVehicleAction('view', vehicle),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
