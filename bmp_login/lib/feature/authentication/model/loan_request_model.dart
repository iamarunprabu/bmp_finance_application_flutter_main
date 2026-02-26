import 'package:bmp_login/domain/entity/loan_request.dart';
import 'package:bmp_login/domain/entity/loan_request_status.dart';
import 'package:bmp_login/core/utils/date_formatter.dart';

class LoanRequestModel extends LoanRequest {
  LoanRequestModel({
    super.id,
    required super.loanNo,
    required super.customerName,
    required super.amount,
    required super.plan,
    required super.requestMonth,
    required super.soldBy,
    super.status = LoanRequestStatus.pending,
    super.remark,
  });

  factory LoanRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanRequestModel(
      id: int.parse(json['id'].toString()),
      loanNo: int.parse(json['loanNo'].toString()),
      customerName: (json['customerName'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      plan: (json['plan'] ?? '').toString(),
      requestMonth: (json['requestMonth'] ?? '').toString(),
      soldBy: (json['soldBy'] ?? '').toString(),
      status: (json['status'] ?? LoanRequestStatus.pending).toString(),
      remark: json['remark']?.toString(),
    );
  }

  @override
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
      // Do not send createdAt or updatedAt from frontend
    };
  }
}
