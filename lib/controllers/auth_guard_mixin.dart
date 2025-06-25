import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'auth_controller.dart';

mixin AuthGuardMixin on GetxController {
  String? getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  void handleNoToken() {
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().logout();
    } else {
      Get.offAllNamed('/login');
    }
  }
}
