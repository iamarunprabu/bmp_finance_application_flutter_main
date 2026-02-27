import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/feature/authentication/loan/data/loan_service.dart';
import 'package:bmp_login/feature/authentication/model/loan_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class LoanListController extends GetxController {
  final LoanService _loanService = LoanService();

  // Reactive State
  final RxList<LoanRequestModel> loanRequests = <LoanRequestModel>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isAdminMode = false.obs;

  String? filterStatus;
  String? filterUsername;

  final screenTitle = ''.obs;
  final loggedInUsername = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('LoanListController onInit called');
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      print('Arguments received: $args');
      isAdminMode.value = args['isAdmin'] ?? false;
      filterStatus = args['status'];
      filterUsername = args['username'];
      screenTitle.value = args['title'] ?? '';
      print('isAdminMode: ${isAdminMode.value}, filterStatus: $filterStatus, screenTitle: ${screenTitle.value}');
    }
    _loadUsernameAndFetch();
  }

  Future<void> _loadUsernameAndFetch() async {
    final username = await JwtStorage.getUsername();
    final role = await JwtStorage.getUserRole();
    loggedInUsername.value = username ?? '';

    // If ROLE_SUPER_ADMIN or ROLE_ADMIN, set username to null
    if (role == 'ROLE_SUPER_ADMIN' || role == 'ROLE_ADMIN') {
      isAdminMode.value = true;
      // For admin mode, only set filterUsername to null if not already set from arguments
      if (filterUsername == null) {
        filterUsername = null;
      }
      print('Admin/SuperAdmin mode - filterUsername: $filterUsername');
    } else {
      // For user mode, use the filterUsername from arguments if provided, otherwise use JWT username
      if (filterUsername == null || filterUsername!.isEmpty) {
        filterUsername = loggedInUsername.value;
        print('User mode - filterUsername set from JWT: $filterUsername');
      } else {
        print('User mode - filterUsername from arguments: $filterUsername');
      }
    }
    fetchUserLoanRequests();
  }

  // --- Data Fetching ---

  Future<void> fetchUserLoanRequests() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      List<LoanRequestModel> requests;
      if (isAdminMode.value) {
        print('Admin mode: ${isAdminMode.value}');
        if (filterStatus != null && filterStatus!.isNotEmpty) {
          final status = filterStatus!.toUpperCase();
          requests = await _loanService.getFilteredRequests(
            status: status,
            username: filterUsername?.isNotEmpty == true ? filterUsername : null,
          );
          print('Fetched ${requests.length} $filterStatus loan requests for Admin (username=$filterUsername)');
        } else {
          requests = await _loanService.getAllRequests();
          print('Fetched ${requests.length} all loan requests for Admin');
        }
      } else {
        // User mode: always use current user's username for filtering
        final currentUsername = await JwtStorage.getUsername();
        if (filterStatus != null && filterStatus!.isNotEmpty) {
          // Use filter endpoint only when status is specified
          requests = await _loanService.getFilteredRequests(
            status: filterStatus!.toUpperCase(),
            username: currentUsername,
          );
          print('Fetched ${requests.length} ${filterStatus} loan requests for User (username=$currentUsername)');
        } else {
          // Use regular user requests endpoint for "All" requests
          requests = await _loanService.getUserRequests();
          print('Fetched ${requests.length} loan requests for User');
        }
      }

      loanRequests.assignAll(requests);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      print('Error fetching user loan requests: $e');

      // Show error popup
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void removeLoanFromList(String loanId) {
    loanRequests.removeWhere((loan) => loan.id.toString() == loanId);
  }

  Future<void> refreshList() async {
    await fetchUserLoanRequests();
  }

  // --- UI Helpers ---

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'CANCELLED_BY_CUSTOMER':
        return Colors.red;
      case 'NOT_ELIGIBLE':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'CANCELLED_BY_CUSTOMER':
        return 'Cancelled';
      case 'NOT_ELIGIBLE':
        return 'Not Eligible';
      default:
        return status;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'APPROVED':
        return Icons.check_circle;
      case 'CANCELLED_BY_CUSTOMER':
        return Icons.cancel;
      case 'NOT_ELIGIBLE':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  Future<void> exportExcel(BuildContext context) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Get external storage and construct Downloads path dynamically
        final externalDir = await getExternalStorageDirectory();
        print('External storage directory: ${externalDir?.path}');
        
        if (externalDir != null) {
          final basePath = externalDir.path.split('/Android')[0];
          print('Base storage path: $basePath');
          
          final downloadsDir = Directory('$basePath/Download');
          print('Downloads directory path: ${downloadsDir.path}');
          print('Downloads directory exists: ${await downloadsDir.exists()}');
          
          // Try Downloads folder first, fallback to external storage
          if (await downloadsDir.exists()) {
            directory = downloadsDir;
            print('Using Downloads directory');
          } else {
            // Try creating Downloads folder
            try {
              directory = await downloadsDir.create(recursive: true);
              print('Created Downloads directory');
            } catch (e) {
              print('Failed to create Downloads directory: $e');
              directory = externalDir; // Fallback to app's external directory
              print('Using external storage directory as fallback');
            }
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final savePath = '${directory.path}/loan_requests.xlsx';
      print('Final save path: $savePath');
      
      final token = await JwtStorage.getToken();
      print('Starting download...');

      final response = await Dio().download(
        'http://10.0.2.2:8080/api/loan/export-excel',
        savePath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      print('Download response status: ${response.statusCode}');
      
      // Check if file was actually created
      final file = File(savePath);
      final fileExists = await file.exists();
      print('File exists after download: $fileExists');
      
      if (fileExists) {
        final fileSize = await file.length();
        print('File size: $fileSize bytes');
      }

      // Try to open the file automatically
      if (fileExists) {
        try {
          final result = await OpenFile.open(savePath);
          print('OpenFile result: ${result.message}');
        } catch (e) {
          print('Could not auto-open file: $e');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fileExists 
              ? 'Excel downloaded successfully to: ${directory.path}'
              : 'Download completed but file not found'),
            backgroundColor: fileExists ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
