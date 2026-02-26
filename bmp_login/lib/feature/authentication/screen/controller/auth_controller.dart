import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/domain/user.dart';
import 'package:bmp_login/presentation/admin_dashboard.dart';
import 'package:bmp_login/presentation/pages/user_dasboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/auth_service.dart';

class AuthController extends GetxController {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final AuthService _service = AuthService();

  // ================= LOGIN =================

  Future<void> login() async {
    try {
      final request = LoginRequest(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      final response = await _service.login(request);

      final userRole = response.user?.role ?? '';
      
      _showPopup(
        title: "Login Successful",
        message: response.message ?? "Welcome ${response.user?.username}",
        isSuccess: true,
        onOk: () {
          if (userRole == "ROLE_SUPER_ADMIN" || userRole == "ROLE_ADMIN") {
            Get.offAll(() => const AdminDashboard());
          } else {
            Get.offAll(() => const UserDasboard());
          }

          emailCtrl.clear();
          passCtrl.clear();
        },
      );
    } catch (e) {
      _showPopup(
        title: "Login Failed",
        message: e.toString().replaceAll("Exception: ", ""),
        isSuccess: false,
      );
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    await _service.logout();
    Get.offAllNamed(ApplicationConstant.login);
  }

  // ================= POPUP =================

  void _showPopup({
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onOk,
  }) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              if (onOk != null) onOk();
            },
            child: const Text("OK"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.onClose();
  }
}
