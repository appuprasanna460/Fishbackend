import '../../domain/entities/fish_entity.dart';

class FishModel extends FishEntity {
  const FishModel({
    required super.id,
    required super.name,
    super.localName,
    super.category,
    super.description,
    super.pricePerKg,
    super.isActive,
    super.createdAt,
  });

  factory FishModel.fromJson(Map<String, dynamic> json) {
    return FishModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      localName: json['localName'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (localName != null) 'localName': localName,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        'pricePerKg': pricePerKg,
        'isActive': isActive,
      };
}
