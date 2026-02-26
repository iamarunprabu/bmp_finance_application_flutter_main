import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bmp_login/core/constant/api_client.dart';
import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/domain/user.dart';
import 'package:bmp_login/feature/authentication/model/login_response.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  // ================= LOGIN =================

  Future<LoginResponse> login(LoginRequest req) async {
    final url = ApplicationConstant.baseUrl + ApplicationConstant.loginApi;

    try {
      final res = await _api
          .post(url, req.toJson())
          .timeout(const Duration(seconds: 15));

      final statusCode = res.statusCode;

      Map<String, dynamic>? bodyJson;

      if (res.body is Map<String, dynamic>) {
        bodyJson = res.body as Map<String, dynamic>;
      } else if (res.body is String) {
        bodyJson = jsonDecode(res.body);
      }

      // ================= SUCCESS =================
      if (statusCode == 200) {
        final token = res.headers['jwt-token'] ??
            res.headers['Jwt-Token'] ??
            res.headers['authorization'] ??
            res.headers['Authorization'];

        if (token == null || token.isEmpty) {
          throw Exception("JWT token not found");
        }

        final cleanToken =
            token.startsWith('Bearer ') ? token.substring(7) : token;

        final loginResponse = LoginResponse.fromJson(bodyJson!, cleanToken);

        await JwtStorage.saveToken(cleanToken);
        await JwtStorage.saveUserRole(loginResponse.user?.role ?? '');

        return loginResponse;
      }

      // ================= ERROR =================
      String backendMessage = "Login Failed";

      if (bodyJson != null && bodyJson.containsKey("message")) {
        backendMessage = bodyJson["message"].toString();
      }

      throw Exception(backendMessage);
    } on TimeoutException {
      throw Exception("Request Timed Out");
    } on SocketException {
      throw Exception("No Internet Connection");
    } catch (e) {
      throw Exception("Unable to process request");
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    try {
      final url = ApplicationConstant.baseUrl + ApplicationConstant.logout;

      await _api.postWithAuth(url, {});
      await JwtStorage.clearAll();
    } catch (_) {
      await JwtStorage.clearAll();
    }
  }

  // ================= AUTH CHECK =================

  Future<bool> isAuthenticated() async {
    final hasToken = await JwtStorage.hasToken();
    if (!hasToken) return false;

    final isExpired = await JwtStorage.isTokenExpired();
    return !isExpired;
  }

  Future<String?> getCurrentUserRole() async {
    return await JwtStorage.getUserRole();
  }
}
