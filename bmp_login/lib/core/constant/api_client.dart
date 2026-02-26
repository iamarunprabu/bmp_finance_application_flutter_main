import 'dart:convert';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client = http.Client();

  Future<http.Response> post(String url, Map body) {
    return _client.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }

  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // ---------------- POST ----------------
  Future<http.Response> postWithAuth(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await JwtStorage.getToken();

    return _client.post(
      Uri.parse(url),
      headers: _headers(token!),
      body: jsonEncode(body),
    );
  }

  // ---------------- GET ----------------
  Future<http.Response> getWithAuth(String url) async {
    final token = await JwtStorage.getToken();

    return _client.get(Uri.parse(url), headers: _headers(token!));
  }

  Future<http.Response> get(String url) async {
    return _client.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );
  }

  // ---------------- PUT ----------------
  Future<http.Response> putWithAuth(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await JwtStorage.getToken();

    return _client.put(
      Uri.parse(url),
      headers: _headers(token!),
      body: jsonEncode(body),
    );
  }

  // ---------------- DELETE ----------------
  Future<http.Response> deleteWithAuth(String url) async {
    final token = await JwtStorage.getToken();

    return _client.delete(Uri.parse(url), headers: _headers(token!));
  }

  Future<http.Response> patchWithAuth(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await JwtStorage.getToken();

    return _client.patch(
      Uri.parse(url),
      headers: _headers(token!),
      body: jsonEncode(body),
    );
  }
}
