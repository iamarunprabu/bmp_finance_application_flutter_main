import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/domain/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/auth_service.dart';

class AuthController extends GetxController {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final AuthService _service = AuthService();
  final RxBool isPasswordVisible = false.obs;

  // ================= LOGIN =================

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final username = await JwtStorage.getSavedUsername();
    final password = await JwtStorage.getSavedPassword();
    if (username != null) emailCtrl.text = username;
    if (password != null) passCtrl.text = password;
  }

  Future<void> login() async {
    try {
      final request = LoginRequest(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      final response = await _service.login(request);

      await JwtStorage.saveCredentials(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      final userRole = response.user?.role ?? '';

      _showAnimatedSuccessPopup(
        message: "Welcome ${response.user?.username}",
        onComplete: () {
          if (userRole == "ROLE_SUPER_ADMIN" || userRole == "ROLE_ADMIN") {
            Get.offAllNamed(ApplicationConstant.adminDashboard);
          } else {
            Get.offAllNamed(ApplicationConstant.userDashboard);
          }
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

  void _showAnimatedSuccessPopup({
    required String message,
    required VoidCallback onComplete,
  }) {
    Get.dialog(
      _SuccessAnimationDialog(message: message),
      barrierDismissible: false,
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      Get.back();
      onComplete();
    });
  }

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

class _SuccessAnimationDialog extends StatefulWidget {
  final String message;

  const _SuccessAnimationDialog({required this.message});

  @override
  State<_SuccessAnimationDialog> createState() =>
      _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _checkAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CheckMarkPainter(_checkAnimation.value),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  Text(
                    'Login Successful!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final double progress;

  _CheckMarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
