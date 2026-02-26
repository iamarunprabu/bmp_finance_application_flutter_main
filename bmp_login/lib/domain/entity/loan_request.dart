import 'package:bmp_login/domain/entity/loan_request_status.dart';

class LoanRequest {
  final int? id;
  final int loanNo;
  final String customerName;
  final double amount;
  final String plan;
  final String requestMonth;
  final String soldBy;
  final String status; // This is the Type (String)
  final String? remark;

  LoanRequest({
    this.id,
    required this.loanNo,
    required this.customerName,
    required this.amount,
    required this.plan,
    required this.requestMonth,
    required this.soldBy,
    this.status = LoanRequestStatus.pending, // Set default value here
    this.remark,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanNo': loanNo,
      'customerName': customerName,
      'amount': amount,
      'plan': plan,
      'requestMonth': requestMonth,
      'soldBy': soldBy,
      'status': status,
      'remark': remark,
    };
  }

  factory LoanRequest.fromJson(Map<String, dynamic> json) {
    return LoanRequest(
      // Ensure ID is a string safely
      id: int.parse(json['id'].toString()),
      loanNo: int.parse(json['loanNo'].toString()),
      customerName: json['customerName'] ?? '',
      // Safe conversion for Oracle NUMBER/Double types
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      plan: json['plan'] ?? '',
      requestMonth: json['requestMonth'] ?? '',
      soldBy: json['soldBy'] ?? '',
      // Fallback to 'PENDING' constant if status is missing from API
      status: json['status'] ?? LoanRequestStatus.pending,
      remark: json['remark']?.toString(),
    );
  }
}
