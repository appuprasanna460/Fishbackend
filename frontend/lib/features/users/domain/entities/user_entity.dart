class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? agentId;
  final String? locationId;
  final String? subLocationId;
  final DateTime? createdAt;
  final int? totalBoats;

  // Registration / profile fields
  final String? companyName;
  final String? referenceBy;
  final String? harbourId;
  final String? harbourName;

  // Subscription / plan fields
  final String? subscriptionPlan;
  final String? subscriptionPlanId;
  final String? planName;
  final int? planDurationDays;
  final double? planPrice;
  final String? subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.agentId,
    this.locationId,
    this.subLocationId,
    this.createdAt,
    this.totalBoats,
    this.companyName,
    this.referenceBy,
    this.harbourId,
    this.harbourName,
    this.subscriptionPlan,
    this.subscriptionPlanId,
    this.planName,
    this.planDurationDays,
    this.planPrice,
    this.subscriptionStatus,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  });

  String get displayRole => role
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
      .join(' ');

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAgent => role == 'COMMISSION_AGENT';
  bool get isOwner => role == 'BOAT_OWNER';
  bool get isStaff => role == 'STAFF';
  bool get isBuyer => role == 'FISH_BUYER';
}