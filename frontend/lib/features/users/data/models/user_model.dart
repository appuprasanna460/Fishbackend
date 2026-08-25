import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required super.isActive,
    super.agentId,
    super.locationId,
    super.subLocationId,
    super.createdAt,
    super.totalBoats,
    super.companyName,
    super.referenceBy,
    super.harbourId,
    super.harbourName,
    super.subscriptionPlan,
    super.subscriptionPlanId,
    super.planName,
    super.planDurationDays,
    super.planPrice,
    super.subscriptionStatus,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    dynamic totalBoatsValue = json['totalBoats'];
    int? totalBoats;
    if (totalBoatsValue != null) {
      if (totalBoatsValue is int) {
        totalBoats = totalBoatsValue;
      } else if (totalBoatsValue is double) {
        totalBoats = totalBoatsValue.toInt();
      } else if (totalBoatsValue is String) {
        totalBoats = int.tryParse(totalBoatsValue);
      }
    }

    String? parseRefId(String fieldName) {
      final value = json[fieldName];
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map) return value['_id'] as String? ?? value['id'] as String?;
      return null;
    }

    String? parseRefName(String fieldName) {
      final value = json[fieldName];
      if (value is Map) {
        return value['name']?.toString();
      }
      return null;
    }

    // Parse harbour (can be a string id or populated object)
    String? harbourId;
    String? harbourName;
    final h = json['harbourId'];
    if (h is Map<String, dynamic>) {
      harbourId = h['_id']?.toString() ?? h['id']?.toString();
      harbourName = h['name']?.toString();
    } else if (h is String) {
      harbourId = h;
    }

    // Parse subscriptionPlanId (can be a string id or populated object)
    String? subscriptionPlanId;
    String? planName;
    int? planDurationDays;
    double? planPrice;
    final p = json['subscriptionPlanId'];
    if (p is Map<String, dynamic>) {
      subscriptionPlanId = p['_id']?.toString() ?? p['id']?.toString();
      planName = p['name']?.toString();
      planDurationDays = p['durationDays'] is num
          ? (p['durationDays'] as num).toInt()
          : null;
      planPrice = p['price'] is num ? (p['price'] as num).toDouble() : null;
    } else if (p is String) {
      subscriptionPlanId = p;
    }

    // Fallback: if plan wasn't populated but snapshot fields exist
    planName ??= json['subscriptionPlanName']?.toString();
    planDurationDays ??= json['subscriptionDurationDays'] is num
        ? (json['subscriptionDurationDays'] as num).toInt()
        : null;

    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'STAFF',
      isActive: json['isActive'] as bool? ?? true,
      agentId: parseRefId('agentId'),
      locationId: parseRefId('locationId'),
      subLocationId: parseRefId('subLocationId'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      totalBoats: totalBoats,
      companyName: json['companyName'] as String?,
      referenceBy: json['referenceBy'] as String?,
      harbourId: harbourId ?? parseRefId('harbourId'),
      harbourName: harbourName ?? parseRefName('harbourId'),
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionPlanId: subscriptionPlanId,
      planName: planName,
      planDurationDays: planDurationDays,
      planPrice: planPrice,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? DateTime.tryParse(json['subscriptionStartDate'] as String)
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.tryParse(json['subscriptionEndDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': isActive,
        if (agentId != null) 'agentId': agentId,
        if (locationId != null) 'locationId': locationId,
        if (subLocationId != null) 'subLocationId': subLocationId,
        if (totalBoats != null) 'totalBoats': totalBoats,
        if (companyName != null) 'companyName': companyName,
        if (referenceBy != null) 'referenceBy': referenceBy,
        if (harbourId != null) 'harbourId': harbourId,
        if (subscriptionPlan != null) 'subscriptionPlan': subscriptionPlan,
        if (subscriptionPlanId != null) 'subscriptionPlanId': subscriptionPlanId,
      };
}