class LocationEntity {
  final String id;
  final String name;
  final String? state;
  final String? district;
  final bool isActive;
  final List<SubLocationEntity> subLocations;

  const LocationEntity({
    required this.id,
    required this.name,
    this.state,
    this.district,
    this.isActive = true,
    this.subLocations = const [],
  });
}

class SubLocationEntity {
  final String id;
  final String name;
  final String locationId;
  final bool isActive;

  const SubLocationEntity({
    required this.id,
    required this.name,
    required this.locationId,
    this.isActive = true,
  });
}
