import '../../domain/entities/tracking_entity.dart';

class TrackingModel extends TrackingEntity {
  const TrackingModel({
    required super.boatId,
    required super.boatNumber,
    required super.boatName,
    super.ownerName,
    required super.latitude,
    required super.longitude,
    super.speed,
    super.heading,
    required super.recordedAt,
    super.status,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    final boat = json['boat'] as Map<String, dynamic>?;
    final coord = json['location'] as Map<String, dynamic>? ??
        json['coordinate'] as Map<String, dynamic>? ??
        json;
    return TrackingModel(
      boatId: boat?['id'] as String? ?? json['boatId'] as String? ?? '',
      boatNumber: boat?['boatNumber'] as String? ?? json['boatNumber'] as String? ?? '',
      boatName: boat?['boatName'] as String? ?? json['boatName'] as String? ?? '',
      ownerName: json['ownerName'] as String?,
      latitude: (coord['latitude'] as num? ?? 0).toDouble(),
      longitude: (coord['longitude'] as num? ?? 0).toDouble(),
      speed: (coord['speed'] as num?)?.toDouble(),
      heading: (coord['heading'] as num?)?.toDouble(),
      recordedAt: DateTime.tryParse(coord['recordedAt'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
}

class TrackingHistoryModel extends TrackingHistoryEntity {
  const TrackingHistoryModel({
    required super.boatId,
    required super.boatNumber,
    required super.path,
    required super.totalDistance,
    required super.averageSpeed,
    required super.totalPoints,
  });

  factory TrackingHistoryModel.fromJson(Map<String, dynamic> json) {
    final boat = json['boat'] as Map<String, dynamic>?;
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final history = (json['history'] as List<dynamic>? ?? [])
        .map((h) => TrackingPointModel.fromJson(h as Map<String, dynamic>))
        .toList();
    return TrackingHistoryModel(
      boatId: boat?['id'] as String? ?? '',
      boatNumber: boat?['boatNumber'] as String? ?? '',
      path: history,
      totalDistance: (summary['distanceTraveled'] as num? ?? 0).toDouble(),
      averageSpeed: (summary['averageSpeed'] as num? ?? 0).toDouble(),
      totalPoints: summary['totalPoints'] as int? ?? 0,
    );
  }
}

class TrackingPointModel extends TrackingPointEntity {
  const TrackingPointModel({
    required super.latitude,
    required super.longitude,
    super.speed,
    super.heading,
    required super.recordedAt,
  });

  factory TrackingPointModel.fromJson(Map<String, dynamic> json) {
    return TrackingPointModel(
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'recordedAt': recordedAt.toIso8601String(),
      };
}
