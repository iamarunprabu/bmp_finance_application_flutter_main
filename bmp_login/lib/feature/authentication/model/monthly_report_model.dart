class MonthlyReportResponse {
  final int year;
  final List<MonthlyReportData> data;

  MonthlyReportResponse({
    required this.year,
    required this.data,
  });

  factory MonthlyReportResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyReportResponse(
      year: json['year'] ?? 0,
      data: (json['data'] as List?)
              ?.map((item) => MonthlyReportData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class MonthlyReportData {
  final String month;
  final int approvedCount;
  final int rejectedCount;
  final int pendingCount;
  final int cancelledCount;
  final double totalLoanAmount;

  MonthlyReportData({
    required this.month,
    required this.approvedCount,
    required this.rejectedCount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.totalLoanAmount,
  });

  factory MonthlyReportData.fromJson(Map<String, dynamic> json) {
    return MonthlyReportData(
      month: json['month'] ?? '',
      approvedCount: json['approvedCount'] ?? 0,
      rejectedCount: json['rejectedCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      cancelledCount: json['cancelledCount'] ?? 0,
      totalLoanAmount: (json['totalLoanAmount'] ?? 0).toDouble(),
    );
  }
}
