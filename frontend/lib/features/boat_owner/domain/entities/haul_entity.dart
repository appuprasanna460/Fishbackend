class HaulEntity {
  final String? id;
  final String voyageId;
  final String boatId;
  final String ownerId;
  final int haulNumber;
  final String fishingGround;
  final String gearType;
  final double netLength;
  final GpsLocation startLocation;
  final List<GpsPoint> gpsTrack;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? duration; // minutes
  final double? distance; // km
  final double? averageSpeed; // km/h
  final String status; // 'ACTIVE' or 'COMPLETED'
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HaulEntity({
    this.id,
    required this.voyageId,
    required this.boatId,
    required this.ownerId,
    required this.haulNumber,
    required this.fishingGround,
    required this.gearType,
    required this.netLength,
    required this.startLocation,
    required this.gpsTrack,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.distance,
    this.averageSpeed,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HaulEntity.fromJson(Map<String, dynamic> json) {
    String vId = '';
    if (json['voyageId'] is Map<String, dynamic>) {
      vId = json['voyageId']['_id'] ?? '';
    } else {
      vId = json['voyageId']?.toString() ?? '';
    }

    String bId = '';
    if (json['boatId'] is Map<String, dynamic>) {
      bId = json['boatId']['_id'] ?? '';
    } else {
      bId = json['boatId']?.toString() ?? '';
    }

    var trackList = json['gpsTrack'] as List? ?? [];
    List<GpsPoint> parsedTrack = trackList.map((e) => GpsPoint.fromJson(e)).toList();

    return HaulEntity(
      id: json['_id'],
      voyageId: vId,
      boatId: bId,
      ownerId: json['ownerId'] ?? '',
      haulNumber: json['haulNumber'] ?? 1,
      fishingGround: json['fishingGround'] ?? '',
      gearType: json['gearType'] ?? '',
      netLength: (json['netLength'] ?? 0).toDouble(),
      startLocation: GpsLocation.fromJson(json['startLocation'] ?? {}),
      gpsTrack: parsedTrack,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']).toLocal() : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']).toLocal() : null,
      duration: json['duration'],
      distance: json['distance'] != null ? (json['distance']).toDouble() : null,
      averageSpeed: json['averageSpeed'] != null ? (json['averageSpeed']).toDouble() : null,
      status: json['status'] ?? 'ACTIVE',
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
    );
  }
}

class GpsLocation {
  final double latitude;
  final double longitude;

  GpsLocation({required this.latitude, required this.longitude});

  factory GpsLocation.fromJson(Map<String, dynamic> json) {
    return GpsLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class GpsPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GpsPoint({required this.latitude, required this.longitude, required this.timestamp});

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    return GpsPoint(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
