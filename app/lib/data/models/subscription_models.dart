class BackendSubscriptionPlan {
  BackendSubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    this.discountLabel,
    this.perMonth,
  });

  final String id;
  final String title;
  final String price;
  final String? discountLabel;
  final String? perMonth;

  factory BackendSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return BackendSubscriptionPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      price: json['price'] as String,
      discountLabel: json['discountLabel'] as String?,
      perMonth: json['perMonth'] as String?,
    );
  }
}

class SubscriptionStatus {
  SubscriptionStatus({required this.status, required this.planId, this.expiresAt});

  final String status;
  final String planId;
  final DateTime? expiresAt;

  bool get isActive => status == 'ACTIVE';

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      status: json['status'] as String,
      planId: json['planId'] as String,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }
}
