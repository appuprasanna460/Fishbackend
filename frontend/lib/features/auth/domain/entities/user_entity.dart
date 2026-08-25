class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? companyName;
  final String role;
  final bool isActive;
  final String? agentId;
  final String? locationId;
  final String? subLocationId;
  final DateTime? createdAt;

  // Subscription fields
  final String? subscriptionPlanName;
  final String? subscriptionStatus; // PENDING_APPROVAL, ACTIVE, EXPIRING_SOON, EXPIRED, NONE
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int? subscriptionDurationDays;

  // User Profile fields
  final String? aboutYou;
  final DateTime? dateOfBirth;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;

  // Company Profile fields
  final String? companyLogo;
  final String? companyId;
  final String? companyEstablishedDate;
  final String? companyType;
  final String? companyRegisteredHarbour;
  final String? companyRegisteredAddress;
  final String? companyGstNumber;
  final String? companyPanNumber;
  final String? companyPhone;
  final String? companyEmail;
  final bool? companyIsVerified;

  // Team Member fields
  final String? ownerId;
  final String? assignedBoatId;
  final String? employeeId;
  final DateTime? joinedDate;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.companyName,
    required this.role,
    required this.isActive,
    this.agentId,
    this.locationId,
    this.subLocationId,
    this.createdAt,
    this.subscriptionPlanName,
    this.subscriptionStatus,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.subscriptionDurationDays,
    this.aboutYou,
    this.dateOfBirth,
    this.address,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.companyLogo,
    this.companyId,
    this.companyEstablishedDate,
    this.companyType,
    this.companyRegisteredHarbour,
    this.companyRegisteredAddress,
    this.companyGstNumber,
    this.companyPanNumber,
    this.companyPhone,
    this.companyEmail,
    this.companyIsVerified,
    this.ownerId,
    this.assignedBoatId,
    this.employeeId,
    this.joinedDate,
  });

  String get displayRole => role
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAgent => role == 'COMMISSION_AGENT';
  bool get isOwner => role == 'BOAT_OWNER';
  bool get isStaff => role == 'STAFF';

  /// Remaining subscription days (0 if expired or no subscription)
  int get remainingSubscriptionDays {
    if (subscriptionEndDate == null) return 0;
    final diff = subscriptionEndDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isSubscriptionExpired =>
      subscriptionStatus == 'EXPIRED' ||
      (subscriptionEndDate != null && subscriptionEndDate!.isBefore(DateTime.now()));

  bool get isSubscriptionExpiringSoon =>
      subscriptionStatus == 'EXPIRING_SOON' ||
      (remainingSubscriptionDays > 0 && remainingSubscriptionDays <= 3);
}
