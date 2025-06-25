import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rentalkuy/services/tracking_service.dart';

class TrackingPage extends StatefulWidget {
  final int bookingId;
  const TrackingPage({super.key, required this.bookingId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  LatLng? _customerLatLng;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLatestLocation();
  }

  Future<void> _fetchLatestLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final box = GetStorage();
      final token = box.read('token');
      final tracking = await TrackingService.getLatestTracking(
        token,
        widget.bookingId,
      );
      if (tracking != null) {
        setState(() {
          _customerLatLng = LatLng(
            double.parse(tracking.latitude),
            double.parse(tracking.longitude),
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Lokasi belum tersedia';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat lokasi: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Customer'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(child: Text(_error!)),
            )
          else if (_customerLatLng == null)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Lokasi tidak ditemukan')),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _customerLatLng!,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _customerLatLng!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchLatestLocation,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
