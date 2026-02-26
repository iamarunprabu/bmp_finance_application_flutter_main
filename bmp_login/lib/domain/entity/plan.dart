class Plan {
  final int? id;
  final String planName;
  final String priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plan({
    this.id,
    required this.planName,
    required this.priority,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'priority': priority,
      // Ensure these are converted to Strings for JSON transport
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      // Ensure id is a String regardless of if the API sends it as an int
      id: json['planId'] ?? json['id'],
      planName: (json['planName'] ?? '').toString(),
      priority: (json['priority'] ?? '0').toString(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null,
    );
  }
}
