import '../../domain/entities/boat_entity.dart';

class BoatModel extends BoatEntity {
  const BoatModel({
    required super.id,
    required super.boatNumber,
    required super.boatName,
    required super.ownerId,
    required super.ownerName,
    required super.agentId,
    required super.agentName,
    super.locationId,
    super.locationName,
    super.subLocationId,
    super.subLocationName,
    super.isActive,
    super.registrationNumber,
    super.registrationDate,
    super.capacity,
    super.createdAt,
  });

  factory BoatModel.fromJson(Map<String, dynamic> json) {
    final owner = json['ownerId'];
    final agent = json['agentId'];
    final loc = json['locationId'];
    final subLoc = json['subLocationId'];

    String parseId(dynamic value) {
      if (value == null) return '';
      if (value is Map) return value['_id'] as String? ?? value['id'] as String? ?? '';
      return value as String? ?? '';
    }

    String parseName(dynamic value) {
      if (value == null) return '';
      if (value is Map) return value['name'] as String? ?? '';
      return '';
    }

    return BoatModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      boatNumber: json['boatNumber'] as String? ?? '',
      boatName: json['boatName'] as String? ?? '',
      ownerId: parseId(owner),
      ownerName: parseName(owner),
      agentId: parseId(agent),
      agentName: parseName(agent),
      locationId: loc is Map ? loc['_id'] as String? : loc as String?,
      locationName: loc is Map ? loc['name'] as String? : null,
      subLocationId: subLoc is Map ? subLoc['_id'] as String? : subLoc as String?,
      subLocationName: subLoc is Map ? subLoc['name'] as String? : null,
      isActive: json['isActive'] as bool? ?? true,
      registrationNumber: json['registrationNumber'] as String?,
      registrationDate: json['registrationDate'] != null
          ? DateTime.tryParse(json['registrationDate'] as String)
          : null,
      capacity: json['capacity'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'boatNumber': boatNumber,
        'boatName': boatName,
        'ownerId': ownerId,
        'agentId': agentId,
        if (locationId != null) 'locationId': locationId,
        if (subLocationId != null) 'subLocationId': subLocationId,
        'isActive': isActive,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (capacity != null) 'capacity': capacity,
      };
}
