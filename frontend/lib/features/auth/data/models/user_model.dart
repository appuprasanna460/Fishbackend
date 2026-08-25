import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.companyName,
    required super.role,
    required super.isActive,
    super.agentId,
    super.locationId,
    super.subLocationId,
    super.createdAt,
    super.subscriptionPlanName,
    super.subscriptionStatus,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
    super.subscriptionDurationDays,
    super.aboutYou,
    super.dateOfBirth,
    super.address,
    super.emergencyContactName,
    super.emergencyContactRelationship,
    super.emergencyContactPhone,
    super.companyLogo,
    super.companyId,
    super.companyEstablishedDate,
    super.companyType,
    super.companyRegisteredHarbour,
    super.companyRegisteredAddress,
    super.companyGstNumber,
    super.companyPanNumber,
    super.companyPhone,
    super.companyEmail,
    super.companyIsVerified,
    super.ownerId,
    super.assignedBoatId,
    super.employeeId,
    super.joinedDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      companyName: json['companyName'] as String?,
      role: json['role'] as String? ?? 'STAFF',
      isActive: json['isActive'] as bool? ?? true,
      agentId: json['agentId'] as String?,
      locationId: json['locationId'] is String
          ? json['locationId'] as String
          : (json['locationId'] as Map<String, dynamic>?)?['_id'] as String?,
      subLocationId: json['subLocationId'] is String
          ? json['subLocationId'] as String
          : (json['subLocationId'] as Map<String, dynamic>?)?['_id'] as String?,
      createdAt: parseDate(json['createdAt']),
      // Subscription fields
      subscriptionPlanName: json['subscriptionPlanName'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      subscriptionStartDate: parseDate(json['subscriptionStartDate']),
      subscriptionEndDate: parseDate(json['subscriptionEndDate']),
      subscriptionDurationDays: parseInt(json['subscriptionDurationDays']),
      // Profile fields
      aboutYou: json['aboutYou'] as String? ?? '',
      dateOfBirth: parseDate(json['dateOfBirth']),
      address: json['address'] as String? ?? '',
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactRelationship: json['emergencyContactRelationship'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      // Company profile fields
      companyLogo: json['companyLogo'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyEstablishedDate: json['companyEstablishedDate'] as String? ?? '',
      companyType: json['companyType'] as String? ?? '',
      companyRegisteredHarbour: json['companyRegisteredHarbour'] as String? ?? '',
      companyRegisteredAddress: json['companyRegisteredAddress'] as String? ?? '',
      companyGstNumber: json['companyGstNumber'] as String? ?? '',
      companyPanNumber: json['companyPanNumber'] as String? ?? '',
      companyPhone: json['companyPhone'] as String? ?? '',
      companyEmail: json['companyEmail'] as String? ?? '',
      companyIsVerified: json['companyIsVerified'] as bool? ?? false,
      // Team fields
      ownerId: json['ownerId'] as String?,
      assignedBoatId: json['assignedBoatId'] is String
          ? json['assignedBoatId'] as String
          : (json['assignedBoatId'] as Map<String, dynamic>?)?['_id'] as String?,
      employeeId: json['employeeId'] as String? ?? '',
      joinedDate: parseDate(json['joinedDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': isActive,
        if (companyName != null) 'companyName': companyName,
        if (agentId != null) 'agentId': agentId,
        if (locationId != null) 'locationId': locationId,
        if (subLocationId != null) 'subLocationId': subLocationId,
        'aboutYou': aboutYou,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        'address': address,
        'emergencyContactName': emergencyContactName,
        'emergencyContactRelationship': emergencyContactRelationship,
        'emergencyContactPhone': emergencyContactPhone,
        'companyLogo': companyLogo,
        'companyId': companyId,
        'companyEstablishedDate': companyEstablishedDate,
        'companyType': companyType,
        'companyRegisteredHarbour': companyRegisteredHarbour,
        'companyRegisteredAddress': companyRegisteredAddress,
        'companyGstNumber': companyGstNumber,
        'companyPanNumber': companyPanNumber,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        'companyIsVerified': companyIsVerified,
        if (ownerId != null) 'ownerId': ownerId,
        if (assignedBoatId != null) 'assignedBoatId': assignedBoatId,
        'employeeId': employeeId,
        if (joinedDate != null) 'joinedDate': joinedDate!.toIso8601String(),
      };
}
