import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    required super.name,
    super.state,
    super.district,
    super.isActive,
    super.subLocations,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final subs = (json['subLocations'] as List<dynamic>? ?? [])
        .map((s) => SubLocationModel.fromJson(s as Map<String, dynamic>))
        .toList();
    return LocationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      state: json['state'] as String?,
      district: json['district'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      subLocations: subs,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (state != null) 'state': state,
        if (district != null) 'district': district,
        'isActive': isActive,
      };
}

class SubLocationModel extends SubLocationEntity {
  const SubLocationModel({
    required super.id,
    required super.name,
    required super.locationId,
    super.isActive,
  });

  factory SubLocationModel.fromJson(Map<String, dynamic> json) {
    return SubLocationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      locationId: json['locationId'] as String? ??
          (json['locationId'] as Map<String, dynamic>?)?['_id'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'locationId': locationId,
        'isActive': isActive,
      };
}
