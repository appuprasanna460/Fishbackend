class FishEntity {
  final String id;
  final String name;
  final String? localName;
  final String? category;
  final String? description;
  final double pricePerKg;
  final bool isActive;
  final DateTime? createdAt;

  const FishEntity({
    required this.id,
    required this.name,
    this.localName,
    this.category,
    this.description,
    this.pricePerKg = 0.0,
    this.isActive = true,
    this.createdAt,
  });

  String get displayName => localName != null ? '$name ($localName)' : name;
}
