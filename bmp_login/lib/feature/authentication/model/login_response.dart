import 'dart:convert';

import 'package:bmp_login/feature/authentication/model/user_model.dart';

class LoginResponse {
  final String token;
  final User? user;
  final String? message;

  LoginResponse({
    required this.token,
    this.user,
    this.message,
  });

  factory LoginResponse.fromJson(
      Map<String, dynamic> json, String token) {
    return LoginResponse(
      token: token,
      user: User.fromJson(json),
      message: 'Login successful',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
      'message': message,
    };
  }

  static LoginResponse? fromResponse(
      String responseBody, String token) {
    try {
      final json = jsonDecode(responseBody);
      return LoginResponse.fromJson(json, token);
    } catch (e) {
      print("❌ Error parsing login response: $e");
      return null;
    }
  }
}
