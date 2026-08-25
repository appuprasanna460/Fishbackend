// lib/features/boats/domain/entities/boat_entity.dart

class BoatEntity {
  final String id;
  final String boatNumber;
  final String boatName;
  final String ownerId;
  final String ownerName;
  final String agentId;
  final String agentName;
  final String? locationId;
  final String? locationName;
  final String? subLocationId;
  final String? subLocationName;
  final bool isActive;
  final String? registrationNumber;
  final DateTime? registrationDate;
  final int? capacity;
  final DateTime? createdAt;

  const BoatEntity({
    required this.id,
    required this.boatNumber,
    required this.boatName,
    required this.ownerId,
    required this.ownerName,
    required this.agentId,
    required this.agentName,
    this.locationId,
    this.locationName,
    this.subLocationId,
    this.subLocationName,
    this.isActive = true,
    this.registrationNumber,
    this.registrationDate,
    this.capacity,
    this.createdAt,
  });

  // ✅ ADD THIS: fromJson factory method
  factory BoatEntity.fromJson(Map<String, dynamic> json) {
    return BoatEntity(
      id: json['_id'] ?? json['id'] ?? '',
      boatNumber: json['boatNumber'] ?? json['number'] ?? '',
      boatName: json['boatName'] ?? json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? json['owner']?['name'] ?? '',
      agentId: json['agentId'] ?? '',
      agentName: json['agentName'] ?? json['agent']?['name'] ?? '',
      locationId: json['locationId'] ?? json['location']?['_id'],
      locationName: json['locationName'] ?? json['location']?['name'],
      subLocationId: json['subLocationId'] ?? json['subLocation']?['_id'],
      subLocationName: json['subLocationName'] ?? json['subLocation']?['name'],
      isActive: json['isActive'] ?? true,
      registrationNumber: json['registrationNumber'],
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : null,
      capacity: json['capacity'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  // ✅ ADD THIS: toJson method (optional but useful)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boatNumber': boatNumber,
      'boatName': boatName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'agentId': agentId,
      'agentName': agentName,
      'locationId': locationId,
      'locationName': locationName,
      'subLocationId': subLocationId,
      'subLocationName': subLocationName,
      'isActive': isActive,
      'registrationNumber': registrationNumber,
      'registrationDate': registrationDate?.toIso8601String(),
      'capacity': capacity,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ✅ ADD THIS: copyWith method (useful for updates)
  BoatEntity copyWith({
    String? id,
    String? boatNumber,
    String? boatName,
    String? ownerId,
    String? ownerName,
    String? agentId,
    String? agentName,
    String? locationId,
    String? locationName,
    String? subLocationId,
    String? subLocationName,
    bool? isActive,
    String? registrationNumber,
    DateTime? registrationDate,
    int? capacity,
    DateTime? createdAt,
  }) {
    return BoatEntity(
      id: id ?? this.id,
      boatNumber: boatNumber ?? this.boatNumber,
      boatName: boatName ?? this.boatName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      subLocationId: subLocationId ?? this.subLocationId,
      subLocationName: subLocationName ?? this.subLocationName,
      isActive: isActive ?? this.isActive,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ✅ ADD THIS: displayName getter (useful for dropdowns)
  String get displayName => '$boatName ($boatNumber)';
}
