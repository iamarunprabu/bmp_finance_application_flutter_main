import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthGuard extends GetMiddleware {

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated
    return null; // Return null to allow navigation
  }

  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    final isAuthenticated = await _checkAuth();

    // If trying to access protected routes without authentication
    if (!isAuthenticated && _isProtectedRoute(route.location)) {
      return GetNavConfig.fromRoute('/role');
    }

    // If authenticated and trying to access login screens
    if (isAuthenticated && _isAuthRoute(route.location)) {
      final role = await JwtStorage.getUserRole();
      if (role == 'ADMIN') {
        return GetNavConfig.fromRoute('/admin-home');
      }
    }

    return null;
  }

  Future<bool> _checkAuth() async {
    final hasToken = await JwtStorage.hasToken();
    if (!hasToken) return false;

    final isExpired = await JwtStorage.isTokenExpired();
    return !isExpired;
  }

  bool _isProtectedRoute(String? route) {
    // List of routes that require authentication
    const protectedRoutes = ['/admin-home', '/user-home'];
    return protectedRoutes.contains(route);
  }

  bool _isAuthRoute(String? route) {
    // List of authentication routes
    const authRoutes = ['/role', '/admin-login', '/user-login'];
    return authRoutes.contains(route);
  }
}
