import 'package:bmp_login/feature/authentication/model/plan_model.dart';
import 'package:bmp_login/presentation/controller/loan_request_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LoanRequestFormScreen extends StatelessWidget {
  const LoanRequestFormScreen({super.key});

  static const _borderColor = Colors.white24;
  static const _labelColor = Colors.white70;
  static const _accentGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (Get.isRegistered<LoanRequestController>()) {
      Get.delete<LoanRequestController>();
    }
    final controller = Get.put(LoanRequestController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Text(
            controller.isViewMode.value ? 'Loan Details' : 'Loan Request',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          final isView = controller.isViewMode.value;

          return Form(
            key: controller.formKey,
            child: Column(
              children: [
                _buildField(
                  controller: controller.loanNoController,
                  label: 'Loan No',
                  hint: 'Auto-generated',
                  icon: Icons.tag,
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                _buildField(
                  controller: controller.customerNameController,
                  label: 'Customer Name',
                  hint: 'Enter customer name',
                  icon: Icons.person_outline,
                  readOnly: isView,
                  validator:
                      (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                _buildField(
                  controller: controller.amountController,
                  label: 'Amount',
                  hint: 'Enter amount',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  readOnly: isView,
                ),
                const SizedBox(height: 20),

                isView
                    ? _buildField(
                      controller: TextEditingController(
                        text: controller.viewPlanName.value,
                      ),
                      label: 'Plan',
                      hint: '',
                      icon: Icons.calendar_today,
                      readOnly: true,
                    )
                    : _buildPlanDropdown(controller),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap:
                      isView
                          ? null
                          : () => controller.pickRequestMonth(context),
                  child: AbsorbPointer(
                    child: _buildField(
                      controller: controller.requestMonthController,
                      label: 'Request Date',
                      hint: 'Select date',
                      icon: Icons.calendar_month,
                      readOnly: isView,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildField(
                  controller: controller.soldByController,
                  label: 'Sold By',
                  hint: 'Current user',
                  icon: Icons.person_pin,
                  readOnly: true,
                ),

                const SizedBox(height: 40),

                if (!isView) _buildSubmitButton(controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(Get.context!);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      decoration: _getInputDecoration(label, hint, icon),
    );
  }

  // ─────────────────────────────────────────────

  Widget _buildPlanDropdown(LoanRequestController controller) {
    final theme = Theme.of(Get.context!);
    return DropdownButtonFormField<PlanModel>(
      value: controller.selectedPlan.value,
      dropdownColor: theme.colorScheme.surface,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      decoration: _getInputDecoration(
        'Plan',
        'Select plan',
        Icons.calendar_today,
      ),
      items:
          controller.planOptions
              .map(
                (plan) =>
                    DropdownMenuItem(value: plan, child: Text(plan.planName)),
              )
              .toList(),
      onChanged: (val) => controller.selectedPlan.value = val,
    );
  }

  // ─────────────────────────────────────────────

  InputDecoration _getInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    final theme = Theme.of(Get.context!);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ─────────────────────────────────────────────

  Widget _buildSubmitButton(LoanRequestController controller) {
    final theme = Theme.of(Get.context!);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            controller.isLoading.value ? null : controller.submitLoanRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'SUBMIT LOAN REQUEST',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
