class CrewEntity {
  final String? id;
  final String ownerId;
  final String name;
  final int age;
  final String phone;
  final String location;
  final String role; // 'CAPTAIN' or 'CREW'
  final bool isActive;
  final bool isAvailable;
  final AssignedTo? assignedTo;
  final int? experience;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CrewEntity({
    this.id,
    required this.ownerId,
    required this.name,
    required this.age,
    required this.phone,
    required this.location,
    required this.role,
    this.isActive = true,
    this.isAvailable = true,
    this.assignedTo,
    this.experience,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CrewEntity.fromJson(Map<String, dynamic> json) {
    return CrewEntity(
      id: json['_id'],
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      role: json['role'] ?? 'CREW',
      isActive: json['isActive'] ?? true,
      isAvailable: json['isAvailable'] ?? true,
      assignedTo: json['assignedTo'] != null ? AssignedTo.fromJson(json['assignedTo']) : null,
      experience: json['experience'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'ownerId': ownerId,
      'name': name,
      'age': age,
      'phone': phone,
      'location': location,
      'role': role,
      'isActive': isActive,
      'isAvailable': isAvailable,
      if (assignedTo != null) 'assignedTo': assignedTo!.toJson(),
      if (experience != null) 'experience': experience,
      if (notes != null) 'notes': notes,
    };
  }
}

class AssignedTo {
  final String voyageId;
  final String boatId;
  final DateTime? assignedAt;

  AssignedTo({
    required this.voyageId,
    required this.boatId,
    this.assignedAt,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
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

    return AssignedTo(
      voyageId: vId,
      boatId: bId,
      assignedAt: json['assignedAt'] != null ? DateTime.parse(json['assignedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voyageId': voyageId,
      'boatId': boatId,
      if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
    };
  }
}
