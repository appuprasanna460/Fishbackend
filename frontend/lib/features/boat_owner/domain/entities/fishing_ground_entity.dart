class FishingGroundEntity {
  final String? id;
  final String ownerId;
  final String name;
  final bool isFavourite;
  final int usedCount;
  final DateTime? lastUsedAt;
  final double totalCatch;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FishingGroundEntity({
    this.id,
    required this.ownerId,
    required this.name,
    this.isFavourite = false,
    this.usedCount = 0,
    this.lastUsedAt,
    this.totalCatch = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory FishingGroundEntity.fromJson(Map<String, dynamic> json) {
    return FishingGroundEntity(
      id: json['_id'],
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      isFavourite: json['isFavourite'] ?? false,
      usedCount: json['usedCount'] ?? 0,
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt']) : null,
      totalCatch: (json['totalCatch'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
