import 'package:bmp_login/feature/authentication/screen/controller/auth_controller.dart';
import 'package:get/get.dart';


class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController());
  }
}
