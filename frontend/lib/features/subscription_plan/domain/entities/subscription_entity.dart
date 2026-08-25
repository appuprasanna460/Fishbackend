// lib/features/subscription_plan/domain/entities/subscription_entity.dart
import 'renewal_request_entity.dart';

class SubscriptionEntity {
  final String planName;
  final String? planId;
  final String status; // ACTIVE, EXPIRING_SOON, EXPIRED, NONE, PENDING_APPROVAL
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int? durationDays;
  final int remainingDays;
  final bool isActive;
  final RenewalRequestEntity? pendingRenewal;

  const SubscriptionEntity({
    required this.planName,
    this.planId,
    required this.status,
    this.startDate,
    this.expiryDate,
    this.durationDays,
    required this.remainingDays,
    required this.isActive,
    this.pendingRenewal,
  });

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) {
    RenewalRequestEntity? pending;
    final pr = json['pendingRenewal'];
    if (pr is Map<String, dynamic>) {
      pending = RenewalRequestEntity.fromJson(pr);
    }

    final rawDays = json['remainingDays'];
    final remaining = rawDays is int
        ? rawDays
        : rawDays is num
            ? rawDays.toInt()
            : 0;

    return SubscriptionEntity(
      planName: json['planName']?.toString() ?? 'None',
      planId: json['planId']?.toString(),
      status: json['status']?.toString() ?? 'NONE',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      durationDays: json['durationDays'] is num
          ? (json['durationDays'] as num).toInt()
          : null,
      remainingDays: remaining,
      isActive: json['isActive'] as bool? ?? false,
      pendingRenewal: pending,
    );
  }

  bool get isExpired => status == 'EXPIRED';
  bool get isExpiringSoon => status == 'EXPIRING_SOON';
  bool get isActive_ => status == 'ACTIVE';
  bool get hasPendingRenewal => pendingRenewal != null;
  bool get canRequestRenewal => !hasPendingRenewal && (isExpired || isExpiringSoon);
}
