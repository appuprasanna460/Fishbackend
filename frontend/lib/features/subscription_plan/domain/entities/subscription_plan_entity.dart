// lib/features/subscription_plan/domain/entities/subscription_plan_entity.dart
class SubscriptionPlanEntity {
  final String? id;
  final String name;
  final double price;
  // durationDays: the authoritative duration from backend (e.g. 90, 180, 365)
  final int durationDays;
  // duration: optional free-text label (e.g. 'Quarter', 'Half') — may be null
  final String? duration;
  final bool isActive;
  final List<String> features;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlanEntity({
    this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.duration,
    this.isActive = true,
    this.features = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanEntity.fromJson(Map<String, dynamic> json) {
    // Parse durationDays — required field; fall back to 0 only if missing (should not happen)
    final rawDays = json['durationDays'];
    final days = rawDays is int
        ? rawDays
        : rawDays is num
            ? rawDays.toInt()
            : 0;

    return SubscriptionPlanEntity(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? 'Plan',
      price: (json['price'] ?? 0).toDouble(),
      durationDays: days,
      duration: json['duration']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      features:
          (json['features'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      if (duration != null) 'duration': duration,
      'isActive': isActive,
      'features': features,
    };
  }

  /// Human-readable duration label — uses actual days, not hardcoded enum
  String get durationLabel {
    if (duration != null && duration!.isNotEmpty) return duration!;
    if (durationDays >= 365) return '${durationDays ~/ 365} Year(s)';
    if (durationDays >= 30) return '${durationDays ~/ 30} Month(s)';
    return '$durationDays Day(s)';
  }

  String get durationDaysLabel => '$durationDays days';

  String get priceLabel => '₹${price.toStringAsFixed(0)}';
}