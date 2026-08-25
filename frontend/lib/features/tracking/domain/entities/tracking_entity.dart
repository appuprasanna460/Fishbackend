class TrackingEntity {
  final String boatId;
  final String boatNumber;
  final String boatName;
  final String? ownerName;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;
  final String status; // ACTIVE | STALE | INACTIVE | UNKNOWN

  const TrackingEntity({
    required this.boatId,
    required this.boatNumber,
    required this.boatName,
    this.ownerName,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.recordedAt,
    this.status = 'UNKNOWN',
  });
}

class TrackingHistoryEntity {
  final String boatId;
  final String boatNumber;
  final List<TrackingPointEntity> path;
  final double totalDistance;
  final double averageSpeed;
  final int totalPoints;

  const TrackingHistoryEntity({
    required this.boatId,
    required this.boatNumber,
    required this.path,
    required this.totalDistance,
    required this.averageSpeed,
    required this.totalPoints,
  });
}

class TrackingPointEntity {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  const TrackingPointEntity({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.recordedAt,
  });
}
