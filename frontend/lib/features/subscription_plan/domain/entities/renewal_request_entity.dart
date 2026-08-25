// lib/features/subscription_plan/domain/entities/renewal_request_entity.dart
class RenewalRequestEntity {
  final String id;
  final String requestedPlanName;
  final int requestedDurationDays;
  final String status; // PENDING, APPROVED, REJECTED, CANCELLED
  final DateTime requestedAt;
  final String? rejectionReason;
  // For admin use: populated user info
  final String? userName;
  final String? userEmail;

  const RenewalRequestEntity({
    required this.id,
    required this.requestedPlanName,
    required this.requestedDurationDays,
    required this.status,
    required this.requestedAt,
    this.rejectionReason,
    this.userName,
    this.userEmail,
  });

  factory RenewalRequestEntity.fromJson(Map<String, dynamic> json) {
    final rawDays = json['requestedDurationDays'];
    final days = rawDays is int
        ? rawDays
        : rawDays is num
            ? rawDays.toInt()
            : 0;

    // userId may be populated (object) or just an id string
    String? userName, userEmail;
    final userId = json['userId'];
    if (userId is Map<String, dynamic>) {
      userName = userId['name']?.toString();
      userEmail = userId['email']?.toString();
    }

    return RenewalRequestEntity(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      requestedPlanName: json['requestedPlanName']?.toString() ?? '',
      requestedDurationDays: days,
      status: json['status']?.toString() ?? 'PENDING',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rejectionReason: json['rejectionReason']?.toString(),
      userName: userName,
      userEmail: userEmail,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
