import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/feature/authentication/loan/data/loan_service.dart';
import 'package:bmp_login/feature/authentication/model/loan_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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

    loggedInUsername.value = username ?? '';

    print('Logged in username: ${loggedInUsername.value}');
    print('isAdminMode : ${isAdminMode.value}, filterStatus : ${filterStatus}');

    if (filterUsername == null || filterUsername!.isEmpty) {
      filterUsername = loggedInUsername.value;
      print('filterUsername set from JWT $filterUsername');
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
        print(isAdminMode.value);
        if (filterStatus != null && filterStatus!.isNotEmpty) {
          final status = filterStatus!.toUpperCase();

          if (status == 'PENDING') {
            // Dedicated pending endpoint
            requests = await _loanService.getFilteredRequests(
              status: status,
              username:
                  filterUsername?.isNotEmpty == true ? filterUsername : null,
            );
            print(
              'Fetched ${requests.length} pending loan requests for Admins (filter: status=$filterStatus, username=$filterUsername)',
            );
          } else {
            // Other status filters
            requests = await _loanService.getFilteredRequests(
              status: status,
              username:
                  filterUsername?.isNotEmpty == true ? filterUsername : null,
            );
            print(
              'Fetched ${requests.length} loan requests for Admin (filter: status=$filterStatus, username=$filterUsername)',
            );
          }
        } else {
          // No filter — fetch all
          requests = await _loanService.getAllRequests();
          print('Fetched ${requests.length} all loan requests for Admin');
        }
      } else {
        requests = await _loanService.getUserRequests();
        print(
          'Fetched ${requests.length} loan requests for User (filter: status=$filterStatus, username=$filterUsername)',
        );
      }

      // Fixed: Actually assigning the results to the reactive list
      loanRequests.assignAll(requests);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error fetching user loan requests: $e');
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

  Future<void> importExcel(BuildContext context) async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      // FIX: Get the actual name of the file picked (e.g., loan_requests_sample.csv)
      String fileName = result.files.single.name;
      final username = await JwtStorage.getUsername();
      // 2. Prepare FormData
      dio.FormData formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          filePath,
          filename:
              fileName, // Use actual name so backend sees the .csv extension
        ),
        'username': username,
      });

      try {
        // Show loading indicator (optional but recommended)

        // Get your auth token
        final token = await JwtStorage.getToken();

        // FIX: Use 10.0.2.2 to talk to your local machine from an Android Emulator
        final response = await dio.Dio().post(
          'http://10.0.2.2:8080/api/loan/import-excel',
          data: formData,
          options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Import complete'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh your dashboard/list
        await refreshList();
      } on dio.DioException catch (e) {
        print('import exception $e');
        String errorMessage = 'Import failed';
        if (e.response?.statusCode == 403) {
          errorMessage = 'Permission Denied: Admin role required.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.type == dio.DioExceptionType.connectionTimeout) {
          errorMessage = 'Cannot reach server. Check IP address.';
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> exportExcel(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // final savePath = '${dir.path}/loan_requests.xlsx';
      final savePath =
          '/storage/emulated/0/Download/loan_requests.xlsx'; //temp folder
      print('Saving Excel to: $savePath');

      final token = await JwtStorage.getToken();

      final response = await Dio().download(
        'http://10.0.2.2:8080/api/loan/export-excel',
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Download status: ${response.statusCode}');

      final file = File(savePath);

      if (await file.exists()) {
        print('File exists at $savePath');

        await OpenFile.open(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel file downloaded and opened.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        print('File does NOT exist at $savePath');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found after download!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      print('DioException: $e');

      if (context.mounted) {
        String msg = e.response?.statusCode == 403
            ? 'Admin access required'
            : 'Export failed';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Other error: $e');

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
