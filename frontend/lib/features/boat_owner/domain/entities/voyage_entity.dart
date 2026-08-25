class VoyageEntity {
  final String? id;
  final String boatId;
  final String? boatName;
  final String? boatNumber;
  final String ownerId;
  final String captainId;
  final String? captainName;
  final String? captainPhone;
  final List<String> crewMembers;
  final List<Map<String, dynamic>>? crewDetails;
  final String departureHarbour;
  final String? departureHarbourName;
  final DateTime departureDate;
  final String departureTime;
  final DateTime endDate;
  final String voyageType; // 'DEEP_SEA' or 'UNDERDEEP'
  final String expectedDuration; // '5-7_DAYS' or '8-9_DAYS'
  final List<String> targetSpecies;
  final List<Map<String, dynamic>>? targetSpeciesDetails;
  final String status; // 'PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED'
  final Supplies supplies;
  final String? notes;
  final Map<String, String>? checklist;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoyageEntity({
    this.id,
    required this.boatId,
    this.boatName,
    this.boatNumber,
    required this.ownerId,
    required this.captainId,
    this.captainName,
    this.captainPhone,
    required this.crewMembers,
    this.crewDetails,
    required this.departureHarbour,
    this.departureHarbourName,
    required this.departureDate,
    required this.departureTime,
    required this.endDate,
    required this.voyageType,
    required this.expectedDuration,
    required this.targetSpecies,
    this.targetSpeciesDetails,
    this.status = 'PLANNED',
    required this.supplies,
    this.notes = '',
    this.checklist,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory VoyageEntity.fromJson(Map<String, dynamic> json) {
    // Parse Boat
    String bId = '';
    String? bName;
    String? bNum;
    if (json['boatId'] is Map<String, dynamic>) {
      bId = json['boatId']['_id'] ?? '';
      bName = json['boatId']['boatName'];
      bNum = json['boatId']['boatNumber'];
    } else {
      bId = json['boatId']?.toString() ?? '';
    }

    // Parse Captain
    String capId = '';
    String? capName;
    String? capPhone;
    if (json['captainId'] is Map<String, dynamic>) {
      capId = json['captainId']['_id'] ?? '';
      capName = json['captainId']['name'];
      capPhone = json['captainId']['phone'];
    } else {
      capId = json['captainId']?.toString() ?? '';
    }

    // Parse Crew
    List<String> crewList = [];
    List<Map<String, dynamic>> crewDetailsList = [];
    if (json['crewMembers'] is List) {
      for (var item in json['crewMembers']) {
        if (item is Map<String, dynamic>) {
          crewList.add(item['_id'] ?? '');
          crewDetailsList.add(item);
        } else {
          crewList.add(item.toString());
        }
      }
    }

    // Parse Harbour
    String harbId = '';
    String? harbName;
    if (json['departureHarbour'] is Map<String, dynamic>) {
      harbId = json['departureHarbour']['_id'] ?? '';
      harbName = json['departureHarbour']['harbourName'];
    } else {
      harbId = json['departureHarbour']?.toString() ?? '';
    }

    // Parse Species
    List<String> speciesList = [];
    List<Map<String, dynamic>> speciesDetailsList = [];
    if (json['targetSpecies'] is List) {
      for (var item in json['targetSpecies']) {
        if (item is Map<String, dynamic>) {
          speciesList.add(item['_id'] ?? '');
          speciesDetailsList.add(item);
        } else {
          speciesList.add(item.toString());
        }
      }
    }

    return VoyageEntity(
      id: json['_id'],
      boatId: bId,
      boatName: bName,
      boatNumber: bNum,
      ownerId: json['ownerId'] ?? '',
      captainId: capId,
      captainName: capName,
      captainPhone: capPhone,
      crewMembers: crewList,
      crewDetails: crewDetailsList.isNotEmpty ? crewDetailsList : null,
      departureHarbour: harbId,
      departureHarbourName: harbName,
      departureDate: json['departureDate'] != null
          ? DateTime.parse(json['departureDate']).toLocal()
          : DateTime.now(),
      departureTime: json['departureTime'] ?? '',
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate']).toLocal()
          : DateTime.now(),
      voyageType: json['voyageType'] ?? 'DEEP_SEA',
      expectedDuration: json['expectedDuration'] ?? '5-7_DAYS',
      targetSpecies: speciesList,
      targetSpeciesDetails: speciesDetailsList.isNotEmpty ? speciesDetailsList : null,
      status: json['status'] ?? 'PLANNED',
      supplies: Supplies.fromJson(json['supplies'] ?? {}),
      notes: json['notes'] ?? '',
      checklist: json['checklist'] != null
          ? Map<String, String>.from(json['checklist'])
          : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']).toLocal() : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']).toLocal() : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']).toLocal() : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'boatId': boatId,
      'ownerId': ownerId,
      'captainId': captainId,
      'crewMembers': crewMembers,
      'departureHarbour': departureHarbour,
      'departureDate': departureDate.toIso8601String(),
      'departureTime': departureTime,
      'endDate': endDate.toIso8601String(),
      'voyageType': voyageType,
      'expectedDuration': expectedDuration,
      'targetSpecies': targetSpecies,
      'status': status,
      'supplies': supplies.toJson(),
      'notes': notes,
      if (checklist != null) 'checklist': checklist,
    };
  }

  VoyageEntity copyWith({
    String? id,
    String? boatId,
    String? boatName,
    String? boatNumber,
    String? ownerId,
    String? captainId,
    String? captainName,
    String? captainPhone,
    List<String>? crewMembers,
    List<Map<String, dynamic>>? crewDetails,
    String? departureHarbour,
    String? departureHarbourName,
    DateTime? departureDate,
    String? departureTime,
    DateTime? endDate,
    String? voyageType,
    String? expectedDuration,
    List<String>? targetSpecies,
    List<Map<String, dynamic>>? targetSpeciesDetails,
    String? status,
    Supplies? supplies,
    String? notes,
    Map<String, String>? checklist,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoyageEntity(
      id: id ?? this.id,
      boatId: boatId ?? this.boatId,
      boatName: boatName ?? this.boatName,
      boatNumber: boatNumber ?? this.boatNumber,
      ownerId: ownerId ?? this.ownerId,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      crewMembers: crewMembers ?? this.crewMembers,
      crewDetails: crewDetails ?? this.crewDetails,
      departureHarbour: departureHarbour ?? this.departureHarbour,
      departureHarbourName: departureHarbourName ?? this.departureHarbourName,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      endDate: endDate ?? this.endDate,
      voyageType: voyageType ?? this.voyageType,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      targetSpecies: targetSpecies ?? this.targetSpecies,
      targetSpeciesDetails: targetSpeciesDetails ?? this.targetSpeciesDetails,
      status: status ?? this.status,
      supplies: supplies ?? this.supplies,
      notes: notes ?? this.notes,
      checklist: checklist ?? this.checklist,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Supplies {
  final double fuelRequired;
  final double fuelInTank;
  final double fuelToCarry; // Auto-calculated
  final double iceRequired;
  final double iceInStock;
  final double iceToCarry; // Auto-calculated
  final double water;
  final String foodSupplies;
  final String otherSupplies;

  Supplies({
    this.fuelRequired = 0,
    this.fuelInTank = 0,
    this.fuelToCarry = 0,
    this.iceRequired = 0,
    this.iceInStock = 0,
    this.iceToCarry = 0,
    this.water = 0,
    this.foodSupplies = '',
    this.otherSupplies = '',
  });

  factory Supplies.fromJson(Map<String, dynamic> json) {
    return Supplies(
      fuelRequired: (json['fuelRequired'] ?? 0).toDouble(),
      fuelInTank: (json['fuelInTank'] ?? 0).toDouble(),
      fuelToCarry: (json['fuelToCarry'] ?? 0).toDouble(),
      iceRequired: (json['iceRequired'] ?? 0).toDouble(),
      iceInStock: (json['iceInStock'] ?? 0).toDouble(),
      iceToCarry: (json['iceToCarry'] ?? 0).toDouble(),
      water: (json['water'] ?? 0).toDouble(),
      foodSupplies: json['foodSupplies'] ?? '',
      otherSupplies: json['otherSupplies'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fuelRequired': fuelRequired,
      'fuelInTank': fuelInTank,
      'fuelToCarry': fuelToCarry,
      'iceRequired': iceRequired,
      'iceInStock': iceInStock,
      'iceToCarry': iceToCarry,
      'water': water,
      'foodSupplies': foodSupplies,
      'otherSupplies': otherSupplies,
    };
  }
}
