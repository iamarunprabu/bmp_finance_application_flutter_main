import 'package:bmp_login/feature/authentication/loan/data/loan_service.dart';
import 'package:bmp_login/feature/authentication/loan/data/plan_service.dart';
import 'package:bmp_login/feature/authentication/model/loan_request_model.dart';
import 'package:bmp_login/feature/authentication/model/plan_model.dart';
import 'package:bmp_login/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/jwt_storage.dart';

class LoanRequestController extends GetxController {
  final LoanService _loanService = LoanService();
  final PlanService _planService = PlanService();

  // Form controllers
  final loanNoController = TextEditingController();
  final customerNameController = TextEditingController();
  final amountController = TextEditingController();
  final requestMonthController = TextEditingController();
  final soldByController = TextEditingController();
  final statusController = TextEditingController();
  final remarkController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // Reactive State
  final RxList<PlanModel> planOptions = <PlanModel>[].obs;
  final Rx<PlanModel?> selectedPlan = Rx<PlanModel?>(null);
  final isLoadingPlans = false.obs;
  final isLoading = false.obs;

  /// View mode: all fields disabled, data from DB, status + remark visible
  final isViewMode = false.obs;

  /// The plan name string when in view mode (dropdown disabled)
  final viewPlanName = ''.obs;

  /// Loan ID for view mode
  String? _viewLoanId;

  @override
  void onInit() {
    super.onInit();

    // Check if opened in view mode with loan data
    if (Get.arguments != null &&
        Get.arguments is Map &&
        Get.arguments['loan'] != null) {
      _initViewMode(Get.arguments['loan'] as LoanRequestModel);
    } else {
      _initializeData();
    }
  }

  /// Initialize view mode: fill all fields from loan data, mark as view-only
  void _initViewMode(LoanRequestModel loan) {
    isViewMode.value = true;
    _viewLoanId = loan.id.toString();

    loanNoController.text = loan.loanNo.toString();
    customerNameController.text = loan.customerName;
    amountController.text = loan.amount.toStringAsFixed(2);
    requestMonthController.text = loan.requestMonth;
    soldByController.text = loan.soldBy;
    statusController.text = _getStatusLabel(loan.status);
    remarkController.text = loan.remark ?? '';
    viewPlanName.value = loan.plan;
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'CANCELLED_BY_CUSTOMER':
        return 'Cancelled by Customer';
      case 'NOT_ELIGIBLE':
        return 'Not Eligible';
      default:
        return status;
    }
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadPlans(),
      _loadNextLoanNumber(),
    ]);
  }

  Future<void> _loadPlans() async {
    try {
      isLoadingPlans.value = true;
      final fetchedPlans = await _planService.getAllPlans();
      planOptions.assignAll(fetchedPlans);
    } catch (e) {
      _showSnackBar('Error', 'Failed to load plans: $e', isError: true);
    } finally {
      isLoadingPlans.value = false;
    }
  }

  Future<void> _loadNextLoanNumber() async {
    try {
      final nextLoanNo = await _loanService.getNextLoanNumber();
      loanNoController.text = nextLoanNo;
    } catch (e) {
      _showSnackBar('Error', 'Failed to load loan number: $e', isError: true);
      loanNoController.text = '1';
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final decodedToken = await JwtStorage.getDecodedToken();
      if (decodedToken != null) {
        soldByController.text = decodedToken['sub'] ?? 'System User';
      }
    } catch (e) {
      soldByController.text = 'User';
    }
  }

  Future<void> pickRequestMonth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      requestMonthController.text = DateFormatter.formatDate(pickedDate);
    }
  }

  Future<void> submitLoanRequest() async {
    if (!formKey.currentState!.validate() || selectedPlan.value == null) {
      _showSnackBar(
        'Form Incomplete',
        'Please check all fields and select a plan',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;

      final loanRequest = LoanRequestModel(
        loanNo: int.tryParse(loanNoController.text.trim()) ?? 0,
        customerName: customerNameController.text.trim(),
        amount: double.tryParse(amountController.text.trim()) ?? 0.0,
        plan: selectedPlan.value!.planName,
        requestMonth: requestMonthController.text.trim(),
        soldBy: soldByController.text.trim(),
        status: 'PENDING',
      );

      final result = await _loanService.createLoanRequest(loanRequest);

      isLoading.value = false;

      if (result['success'] == true) {
        await _showAnimatedSuccessDialog();
        clearForm();
        // Navigate to loan list page showing all loans for current user
        final username = await JwtStorage.getUsername();
        Get.offNamed('/loan-request-list', arguments: {
          'isAdmin': false,
          'status': 'ALL',
          'username': username,
          'title': 'My Loan Requests',
        });
      } else {
        _showSnackBar(
          'Request Failed',
          result['message'] ?? 'Unknown error',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error', 'An unexpected error occurred: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _showAnimatedSuccessDialog() async {
    await Get.dialog(
      _SuccessAnimationDialog(),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
    );
  }

  void _showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
      colorText: isError ? Colors.red.shade900 : Colors.green.shade900,
      snackPosition: SnackPosition.TOP,
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle_outline),
    );
  }

  void clearForm() {
    loanNoController.clear();
    customerNameController.clear();
    amountController.clear();
    requestMonthController.clear();
    statusController.clear();
    remarkController.clear();
    selectedPlan.value = null;
  }

  @override
  void onClose() {
    loanNoController.dispose();
    customerNameController.dispose();
    amountController.dispose();
    requestMonthController.dispose();
    soldByController.dispose();
    statusController.dispose();
    remarkController.dispose();
    super.onClose();
  }
}

/// Animated Success Dialog Widget
class _SuccessAnimationDialog extends StatefulWidget {
  @override
  State<_SuccessAnimationDialog> createState() =>
      _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    // Chain animations
    _scaleController.forward().then((_) {
      _checkController.forward().then((_) {
        _textController.forward();
      });
    });

    // Auto-close after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Get.isDialogOpen == true) {
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circle with checkmark
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _checkAnimation,
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Animated success text
            FadeTransition(
              opacity: _textAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_textAnimation),
                child: Column(
                  children: [
                    Text(
                      'Saved Successfully!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your loan request has been submitted.\nRedirecting to your requests...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Animated progress indicator
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
