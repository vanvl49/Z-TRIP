import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/home_page.dart';
import '../pages/profil_page.dart';
import 'package:rentalkuy/views/pages/daftar_kendaraan_page.dart';
import 'package:rentalkuy/controllers/profile_controller.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 1; // Home di tengah

  final List<Widget> _pages = [
    const DaftarKendaraanSewaView(), // index 0
    const HomePage(), // index 1 (Home)
    const ProfilPage(), // index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int selectedIndex) {
          setState(() {
            _currentIndex = selectedIndex;
            // Jika tab profil, reload profile
            if (_currentIndex == 2 && Get.isRegistered<ProfileController>()) {
              Get.find<ProfileController>().loadProfile();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_filled),
            label: 'Kendaraan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
      ),
    );
  }
}
