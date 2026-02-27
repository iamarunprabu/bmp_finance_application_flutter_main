import 'dart:convert';
import 'package:bmp_login/core/constant/api_client.dart';
import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/feature/authentication/model/loan_request_model.dart';

class LoanService {
  final ApiClient _api = ApiClient();
  final String _basePath = '${ApplicationConstant.baseUrl}/api/loan';

  /// 1. Get ALL requests (Admin)
  Future<List<LoanRequestModel>> getAllRequests() async {
    try {
      // Logic: ApiClient already attaches headers internally
      final res = await _api.getWithAuth('$_basePath/requests/all');
      return _mapToList(res);
    } catch (e) {
      throw Exception('Failed to fetch all requests: $e');
    }
  }

  /// 2. Get USER specific requests
  Future<List<LoanRequestModel>> getUserRequests() async {
    try {
      final res = await _api.getWithAuth('$_basePath/requests');
      return _mapToList(res);
    } catch (e) {
      throw Exception('Failed to fetch user requests: $e');
    }
  }

  /// 2a. Get ALL requests by username
  Future<List<LoanRequestModel>> getAllRequestsByUsername(String username) async {
    try {
      final res = await _api.getWithAuth('$_basePath/requests/all?username=$username');
      return _mapToList(res);
    } catch (e) {
      throw Exception('Failed to fetch all requests for user: $e');
    }
  }

  /// 2b. Get PENDING requests (Admin) — kept for backward compat
  Future<List<LoanRequestModel>> getPendingRequests() async {
    try {
      final res = await _api.getWithAuth('$_basePath/requests/pending');
      return _mapToList(res);
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// 2c. Dynamic filter: optional status & username query params
  /// GET /api/loan/requests/filter?status=PENDING&username=john
  Future<List<LoanRequestModel>> getFilteredRequests({
    String? status,
    String? username,
  }) async {
    try {
      // Build query string from non-null params
      final params = <String, String>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      // Always add username parameter, even if empty
      params['username'] = username ?? '';

      String url = '$_basePath/requests/filter';
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$query';

      print('Filter URL: $url');
      final res = await _api.getWithAuth(url);
      return _mapToList(res);
    } catch (e) {
      throw Exception('Failed to fetch filtered requests: $e');
    }
  }

  /// 3. Get request by ID
  Future<LoanRequestModel> getRequestById(String id) async {
    try {
      final res = await _api.getWithAuth('$_basePath/request/$id');
      if (res.statusCode == 200) {
        return LoanRequestModel.fromJson(json.decode(res.body));
      }
      throw Exception('Request not found');
    } catch (e) {
      throw Exception('Error fetching request $id: $e');
    }
  }

  /// 4. Create loan request
  Future<Map<String, dynamic>> createLoanRequest(
    LoanRequestModel loanRequest,
  ) async {
    try {
      print('=== CREATE LOAN REQUEST ===');
      print('Request Body: ${json.encode(loanRequest.toJson())}');

      final res = await _api.postWithAuth(
        '$_basePath/request',
        loanRequest.toJson(),
      );

      print('Response Status: ${res.statusCode}');
      print('Response Body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final responseData = json.decode(res.body);
        return {
          'success': responseData['success'] ?? true,
          'message':
              responseData['message'] ?? 'Loan request created successfully',
          'data': responseData['data'],
        };
      } else {
        String errorMessage = 'Failed to create loan request';
        try {
          final errorData = json.decode(res.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Server error: ${res.statusCode}';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in createLoanRequest: $e');
      return {'success': false, 'message': 'Error creating loan request: $e'};
    }
  }

  /// 5. Update request
  Future<void> updateLoanRequest(
    String id,
    LoanRequestModel loanRequest,
  ) async {
    try {
      await _api.putWithAuth('$_basePath/request/$id', loanRequest.toJson());
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// 5b. Update loan status and remark (Admin)
  Future<Map<String, dynamic>> updateLoanStatus(
    String id,
    String status,
    String remark,
  ) async {
    try {
      final res = await _api.putWithAuth('$_basePath/request/$id/status', {
        'status': status,
        'remark': remark,
      });

      print('UpdateStatus Response: ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Status updated',
        };
      } else {
        String errorMsg = 'Failed to update status';
        try {
          final errBody = json.decode(res.body);
          errorMsg = errBody['message'] ?? errorMsg;
        } catch (_) {}
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating status: $e'};
    }
  }

  /// 6. Delete request
  Future<void> deleteLoanRequest(String id) async {
    try {
      final res = await _api.deleteWithAuth('$_basePath/request/$id');
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('Delete failed with status: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }

  /// 7. Get next loan number
  Future<String> getNextLoanNumber() async {
    try {
      final res = await _api.getWithAuth('$_basePath/next-loan-number');

      print('Next Loan Number Response Status: ${res.statusCode}');
      print('Next Loan Number Response Body: ${res.body}');

      if (res.statusCode == 200) {
        // Handle different response formats
        String body = res.body.trim();
        // Remove quotes if present
        if (body.startsWith('"') && body.endsWith('"')) {
          body = body.substring(1, body.length - 1);
        }
        return body;
      }
      throw Exception(
        'Failed to get next loan number: Status ${res.statusCode}',
      );
    } catch (e) {
      print('Error in getNextLoanNumber: $e');
      throw Exception('Error getting next loan number: $e');
    }
  }

  // Helper to convert dynamic response body to a typed List
  List<LoanRequestModel> _mapToList(dynamic res) {
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((item) => LoanRequestModel.fromJson(item)).toList();
    }
    String errorMsg = 'Server error: ${res.statusCode}';
    try {
      final body = json.decode(res.body);

      if (body is Map && body['message'] != null) {
        errorMsg = body['message'];
      }
    } catch (_) {
      // Ignore JSON parse errors
    }

    if (res.statusCode == 403) {
      throw Exception(
        'Access Denied (403): You do not have permission to access this resource.',
      );
    } else if (res.statusCode == 401) {
      throw Exception('Unauthorized (401): Please login again.');
    } else {
      throw Exception(errorMsg);
    }
  }

  Future<List<LoanRequestModel>> paginationFilter({
    required int page,
    int size = 20,
    String? keyword,
  }) async {
    try {
      final url =
          '/userh/requests/paginated?page=$page&size=$size&keyword=${keyword ?? ''}';

      final res = await _api.getWithAuth(url);

      return _mapToList(res);
    } catch (e) {
      throw Exception(
        'Failed to fetch paginated loan requests: $e',
      );
    }
  }
}
