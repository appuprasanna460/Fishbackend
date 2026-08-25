class CatchEntity {
  final String? id;
  final String haulId;
  final String voyageId;
  final String ownerId;
  final String species;
  final double weight; // kg
  final int boxes;
  final double sharePercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CatchEntity({
    this.id,
    required this.haulId,
    required this.voyageId,
    required this.ownerId,
    required this.species,
    required this.weight,
    required this.boxes,
    required this.sharePercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory CatchEntity.fromJson(Map<String, dynamic> json) {
    return CatchEntity(
      id: json['_id'],
      haulId: json['haulId'] is Map ? json['haulId']['_id'] : json['haulId'],
      voyageId: json['voyageId'] is Map ? json['voyageId']['_id'] : json['voyageId'],
      ownerId: json['ownerId'] ?? '',
      species: json['species'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      boxes: json['boxes'] ?? 0,
      sharePercentage: (json['sharePercentage'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'haulId': haulId,
      'voyageId': voyageId,
      'ownerId': ownerId,
      'species': species,
      'weight': weight,
      'boxes': boxes,
      'sharePercentage': sharePercentage,
    };
  }
}
