import 'package:bmp_login/domain/entity/loan_request_status.dart';
import 'package:bmp_login/feature/authentication/loan/data/loan_service.dart';
import 'package:bmp_login/feature/authentication/model/loan_request_model.dart';
import 'package:bmp_login/presentation/screen/animation/update_success_animation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoanDetailDialog extends StatefulWidget {
  final LoanRequestModel loan;
  final VoidCallback? onUpdated;

  const LoanDetailDialog({super.key, required this.loan, this.onUpdated});

  static Future<void> show(
    BuildContext context, {
    required LoanRequestModel loan,
    VoidCallback? onUpdated,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Loan Detail',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder:
          (_, __, ___) => LoanDetailDialog(loan: loan, onUpdated: onUpdated),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<LoanDetailDialog> createState() => _LoanDetailDialogState();
}

class _LoanDetailDialogState extends State<LoanDetailDialog>
    with TickerProviderStateMixin {
  final LoanService _loanService = LoanService();
  final TextEditingController _remarkController = TextEditingController();

  late String _selectedStatus;
  bool _isUpdating = false;
  bool _showRemark = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.loan.status.toUpperCase();
    _remarkController.text = widget.loan.remark ?? '';

    _showRemark =
        _selectedStatus != 'PENDING' || _remarkController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    final result = await _loanService.updateLoanStatus(
      widget.loan.id!.toString(),
      _selectedStatus,
      _remarkController.text.trim(),
    );

    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (result['success'] == true) {
      widget.onUpdated?.call();
      Navigator.of(context).pop();

      await Get.dialog(
        UpdateSuccessAnimationDialog(
          statusLabel: LoanRequestStatus.getLabel(_selectedStatus),
        ),
        barrierDismissible: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = LoanRequestStatus.getColor(_selectedStatus);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(statusColor),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(
                      Icons.receipt_long,
                      'Loan No',
                      widget.loan.loanNo.toString(),
                    ),
                    _buildReadOnlyField(
                      Icons.person_outline,
                      'Customer Name',
                      widget.loan.customerName,
                    ),
                    _buildReadOnlyField(
                      Icons.currency_rupee,
                      'Amount',
                      '₹${widget.loan.amount.toStringAsFixed(2)}',
                    ),
                    _buildReadOnlyField(
                      Icons.calendar_today,
                      'Plan',
                      widget.loan.plan,
                    ),
                    _buildReadOnlyField(
                      Icons.date_range,
                      'Request Date',
                      widget.loan.requestMonth,
                    ),
                    _buildReadOnlyField(
                      Icons.storefront,
                      'Sold By',
                      widget.loan.soldBy,
                    ),
                    const SizedBox(height: 20),
                    _buildStatusDropdown(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child:
                          _showRemark
                              ? _buildRemarkField()
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    _buildUpdateButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Loan Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      dropdownColor: theme.colorScheme.surface,
      decoration: InputDecoration(
        labelText: 'Update Status',
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      items:
          LoanRequestStatus.allStatuses
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(LoanRequestStatus.getLabel(status)),
                ),
              )
              .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedStatus = value;
          _showRemark = true;
        });
      },
    );
  }

  Widget _buildRemarkField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        controller: _remarkController,
        maxLines: 3,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: 'Admin Remark',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          hintText: 'Enter remark...',
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    final theme = Theme.of(context);
    final hasChanges = _selectedStatus != widget.loan.status.toUpperCase();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: hasChanges && !_isUpdating ? _handleUpdate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              hasChanges ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.5),
          disabledBackgroundColor: theme.colorScheme.surface.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasChanges ? 4 : 0,
        ),
        child:
            _isUpdating
                ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.onPrimary,
                    strokeWidth: 2.5,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasChanges ? Icons.check_circle : Icons.info_outline,
                      color:
                          hasChanges
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasChanges ? 'Update Status' : 'No Changes',
                      style: TextStyle(
                        color:
                            hasChanges
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(0.3),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
