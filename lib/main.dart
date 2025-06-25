import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'views/widgets/bottom_navbar.dart';
import 'views/pages/login_page.dart';
import 'views/pages/register_page.dart';
import 'views/pages/home_page.dart';
import 'controllers/auth_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'controllers/vehicle_unit_controller.dart';
import 'controllers/profile_controller.dart';
import 'package:rentalkuy/controllers/transaction_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize controllers
  Get.put(AuthController());
  Get.put(VehicleController());
  Get.put(VehicleUnitController());
  Get.put(ProfileController()); // Tambahkan ini!
  Get.put(TransactionController()); // Tambahkan baris ini

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Z-TRIP Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const BottomNavBar(), // Ganti dari HomePage ke BottomNavBar
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => const BottomNavBar(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
