// lib/features/billing/domain/entities/bill_entity.dart

class BillEntity {
  final String id;
  final String billNumber;
  final String boatId;
  final String boatNumber;
  final String boatName;
  final String staffId;
  final String staffName; // ✅ ADD THIS
  final String agentId;
  final String agentName;
  final DateTime billDate;
  final List<FishEntryEntity> fishEntries;
  final double totalWeight;
  final double totalAmount;
  final double commissionAmount;
  final double netAmount;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const BillEntity({
    required this.id,
    required this.billNumber,
    required this.boatId,
    required this.boatNumber,
    required this.boatName,
    this.staffId = '',
    this.staffName = '', // ✅ ADD THIS
    required this.agentId,
    required this.agentName,
    required this.billDate,
    required this.fishEntries,
    required this.totalWeight,
    required this.totalAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
    this.notes,
    this.createdAt,
  });

  // ✅ ADD THIS - fromJson factory method
  factory BillEntity.fromJson(Map<String, dynamic> json) {
    // Parse fish entries
    final fishEntries = (json['fishEntries'] as List? ?? [])
        .map((e) => FishEntryEntity.fromJson(e))
        .toList();

    // ✅ Parse boat data
    String boatId = '';
    String boatNumber = '';
    String boatName = '';
    final boatData = json['boatId'];
    if (boatData is Map<String, dynamic>) {
      boatId = boatData['_id'] ?? '';
      boatNumber = boatData['boatNumber'] ?? '';
      boatName = boatData['boatName'] ?? '';
    } else if (boatData is String) {
      boatId = boatData;
      boatNumber = json['boatNumber'] ?? '';
      boatName = json['boatName'] ?? '';
    }

    // ✅ Parse agent data - THIS IS THE KEY FIX
    String agentId = '';
    String agentName = '';
    final agentData = json['agentId'];
    if (agentData is Map<String, dynamic>) {
      agentId = agentData['_id'] ?? '';
      agentName = agentData['name'] ?? '';
    } else if (agentData is String) {
      agentId = agentData;
      agentName = json['agentName'] ?? '';
    }

    // ✅ Parse staff data
    String staffId = '';
    String staffName = '';
    final staffData = json['staffId'];
    if (staffData is Map<String, dynamic>) {
      staffId = staffData['_id'] ?? '';
      staffName = staffData['name'] ?? '';
    } else if (staffData is String) {
      staffId = staffData;
      staffName = json['staffName'] ?? '';
    }

    // ✅ Debug - print parsed values
    print('📊 Parsing bill: ${json['billNumber']}');
    print('📊   agentName: "$agentName"');
    print('📊   staffName: "$staffName"');

    return BillEntity(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      boatId: boatId,
      boatNumber: boatNumber,
      boatName: boatName,
      staffId: staffId,
      staffName: staffName, // ✅ Now populated
      agentId: agentId,
      agentName: agentName, // ✅ Now populated
      billDate: json['billDate'] != null
          ? DateTime.parse(json['billDate'])
          : DateTime.now(),
      fishEntries: fishEntries,
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'CONFIRMED',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  // ✅ Optional: toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billNumber': billNumber,
      'boatId': boatId,
      'boatNumber': boatNumber,
      'boatName': boatName,
      'staffId': staffId,
      'staffName': staffName,
      'agentId': agentId,
      'agentName': agentName,
      'billDate': billDate.toIso8601String(),
      'fishEntries': fishEntries.map((e) => e.toJson()).toList(),
      'totalWeight': totalWeight,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'netAmount': netAmount,
      'status': status,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

//  Update FishEntryEntity with fromJson
class FishEntryEntity {
  final String fishId;
  final String fishName;
  final double weight;
  final double rate;
  final double amount;

  const FishEntryEntity({
    required this.fishId,
    required this.fishName,
    required this.weight,
    required this.rate,
    required this.amount,
  });

  factory FishEntryEntity.fromJson(Map<String, dynamic> json) {
    // Parse fishId - could be string or object
    String fishId = '';
    final fishData = json['fishId'];
    if (fishData is Map<String, dynamic>) {
      fishId = fishData['_id'] ?? '';
    } else if (fishData is String) {
      fishId = fishData;
    }

    return FishEntryEntity(
      fishId: fishId,
      fishName: json['fishName'] ?? '',
      weight: (json['weightKg'] ?? json['weight'] ?? 0).toDouble(),
      rate: (json['pricePerKg'] ?? json['rate'] ?? 0).toDouble(),
      amount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fishId': fishId,
      'fishName': fishName,
      'weightKg': weight,
      'pricePerKg': rate,
      'totalAmount': amount,
    };
  }
}
