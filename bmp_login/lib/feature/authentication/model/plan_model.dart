import 'package:bmp_login/core/utils/date_formatter.dart';
import 'package:bmp_login/domain/entity/plan.dart';

class PlanModel extends Plan {
  PlanModel({
    super.id,
    required super.planName,
    required super.priority,
    super.createdAt,
    super.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      // 1. Safe conversion for ID: handle int or string from backend
      id: (json['planId'] ?? json['id'] ?? ''),

      // 2. Ensure planName is a string
      planName: (json['planName'] ?? '').toString(),

      // 3. Safe conversion for priority: handle int or string
      priority: (json['priority'] ?? '0').toString(),

      // 4. Robust Date Parsing
      createdAt:
          json['createdAt'] != null
              ? DateFormatter.parseDate(json['createdAt'].toString()):null,
      updatedAt:
          json['updatedAt'] != null
              ? DateFormatter.parseDate(json['updatedAt'].toString()):null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'planId': id,
      'planName': planName,
      'priority': priority,
      'createdAt': createdAt !=null ? DateFormatter.formatForApi(createdAt!):null,
      'updatedAt': updatedAt !=null ? DateFormatter.formatForApi(updatedAt!):null,
    };
  }

  Plan toEntity() => Plan(
    id: id,
    planName: planName,
    priority: priority,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
