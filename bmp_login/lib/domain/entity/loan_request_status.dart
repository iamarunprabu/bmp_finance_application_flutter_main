import 'package:flutter/material.dart';

class LoanRequestStatus {
  // Constants matching your Java Enum/Oracle values
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String cancelledByCustomer = 'CANCELLED_BY_CUSTOMER';
  static const String notEligible = 'NOT_ELIGIBLE';

  static List<String> get allStatuses => [
    pending,
    approved,
    cancelledByCustomer,
    notEligible,
  ];

  // Logic for UI mapping
  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case cancelledByCustomer:
        return 'Cancelled by Customer';
      case notEligible:
        return 'Not Eligible';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case approved:
        return Colors.green;
      case cancelledByCustomer:
        return Colors.red;
      case notEligible:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
