import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    return _checkAuth();
  }

  RouteSettings? _checkAuth() {
    isAuthenticated().then((isAuth) {
      if (!isAuth) {
        Get.offAllNamed(ApplicationConstant.login);
      }
    });
    return null;
  }

  Future<bool> isAuthenticated() async {
    final hasToken = await JwtStorage.hasToken();
    if (!hasToken) return false;

    final isExpired = await JwtStorage.isTokenExpired();
    if (isExpired) {
      await JwtStorage.clearAll();
      return false;
    }

    return true;
  }
}
