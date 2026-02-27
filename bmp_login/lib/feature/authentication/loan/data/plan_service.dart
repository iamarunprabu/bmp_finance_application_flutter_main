import 'dart:convert';
import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/feature/authentication/model/plan_model.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/jwt_storage.dart';

class PlanService {
  /// Centralized method to handle headers and Authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await JwtStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PlanModel>> getAllPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/plans/all'),
        headers: await _getHeaders(),
      );

      return _handleResponseList(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  Future<PlanModel> createPlan(PlanModel plan) async {
    try {
      final response = await http.post(
        Uri.parse('${ApplicationConstant.baseUrl}/api/plans'),
        headers: await _getHeaders(),
        body: json.encode(plan.toJson()),
      );

      return _handleResponseSingle(response, expectedStatus: 201);
    } catch (e) {
      throw Exception('Create Plan Error: $e');
    }
  }

  Future<PlanModel> updatePlan(String id, PlanModel plan) async {
    try {
      final response = await http.put(
        Uri.parse('${ApplicationConstant.baseUrl}/api/plans/$id'),
        headers: await _getHeaders(),
        body: json.encode(plan.toJson()),
      );

      return _handleResponseSingle(response);
    } catch (e) {
      throw Exception('Update Plan Error: $e');
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApplicationConstant.baseUrl}/api/plans/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Delete failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Delete Plan Error: $e');
    }
  }

  // --- Helper Methods to reduce boiler plate ---

  List<PlanModel> _handleResponseList(http.Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => PlanModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Server Error [${response.statusCode}]: ${response.body}',
      );
    }
  }

  PlanModel _handleResponseSingle(
    http.Response response, {
    int expectedStatus = 200,
  }) {
    if (response.statusCode == expectedStatus || response.statusCode == 200) {
      return PlanModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Server Error [${response.statusCode}]: ${response.body}',
      );
    }
  }
}
