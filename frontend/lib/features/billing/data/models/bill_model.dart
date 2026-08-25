// lib/features/billing/data/models/bill_model.dart

import '../../domain/entities/bill_entity.dart';

class BillModel {
  final String id;
  final String billNumber;
  final String boatId;
  final String boatNumber;
  final String boatName;
  final String staffId;
  final String staffName;
  final String agentId;
  final String agentName;
  final DateTime billDate;
  final List<FishEntryModel> fishEntries;
  final double totalWeight;
  final double totalAmount;
  final double commissionAmount;
  final double netAmount;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  BillModel({
    required this.id,
    required this.billNumber,
    required this.boatId,
    required this.boatNumber,
    required this.boatName,
    this.staffId = '',
    this.staffName = '',
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

  // ✅ fromJson factory method
  factory BillModel.fromJson(Map<String, dynamic> json) {
    print('🟡 [MODEL] Parsing bill from JSON: ${json['billNumber']}');

    // Parse fish entries
    final fishEntries = (json['fishEntries'] as List? ?? [])
        .map((e) => FishEntryModel.fromJson(e))
        .toList();

    // Parse boat data
    String boatId = '';
    String boatNumber = '';
    String boatName = '';
    final boatData = json['boatId'];
    if (boatData is Map<String, dynamic>) {
      boatId = boatData['_id']?.toString() ?? '';
      boatNumber = boatData['boatNumber']?.toString() ?? '';
      boatName = boatData['boatName']?.toString() ?? '';
    } else if (boatData is String) {
      boatId = boatData;
      boatNumber = json['boatNumber']?.toString() ?? '';
      boatName = json['boatName']?.toString() ?? '';
    }

    // ✅ FIX: Parse agent data - handle both object and string
    String agentId = '';
    String agentName = '';
    final agentData = json['agentId'];

    print('🟡 [MODEL] agentData type: ${agentData.runtimeType}');
    print('🟡 [MODEL] agentData: $agentData');

    if (agentData is Map<String, dynamic>) {
      // ✅ Agent is an object with _id and name
      agentId = agentData['_id']?.toString() ?? '';
      agentName = agentData['name']?.toString() ?? '';
      // If name is empty, try other fields
      if (agentName.isEmpty) {
        agentName = agentData['agentName']?.toString() ?? '';
      }
    } else if (agentData is String) {
      // Agent is just an ID string
      agentId = agentData;
      agentName = json['agentName']?.toString() ?? '';
    }

    // ✅ FIX: Parse staff data
    String staffId = '';
    String staffName = '';
    final staffData = json['staffId'];

    if (staffData is Map<String, dynamic>) {
      staffId = staffData['_id']?.toString() ?? '';
      staffName = staffData['name']?.toString() ?? '';
    } else if (staffData is String) {
      staffId = staffData;
      staffName = json['staffName']?.toString() ?? '';
    }

    // ✅ Debug parsed values
    print('🟡 [MODEL] Parsed agentId: "$agentId"');
    print('🟡 [MODEL] Parsed agentName: "$agentName"');
    print('🟡 [MODEL] Parsed staffId: "$staffId"');
    print('🟡 [MODEL] Parsed staffName: "$staffName"');

    return BillModel(
      id: json['_id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      boatId: boatId,
      boatNumber: boatNumber,
      boatName: boatName,
      staffId: staffId,
      staffName: staffName,
      agentId: agentId,
      agentName: agentName,
      billDate: json['billDate'] != null
          ? DateTime.parse(json['billDate'].toString())
          : DateTime.now(),
      fishEntries: fishEntries,
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? json['grandTotal'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'DRAFT',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
    );
  }

  // ✅ Convert to BillEntity
  BillEntity toEntity() {
    print('🔴 [TO_ENTITY] Converting bill: $billNumber');
    print('🔴 [TO_ENTITY] agentName: "$agentName"');
    print('🔴 [TO_ENTITY] staffName: "$staffName"');

    return BillEntity(
      id: id,
      billNumber: billNumber,
      boatId: boatId,
      boatNumber: boatNumber,
      boatName: boatName,
      staffId: staffId,
      staffName: staffName,
      agentId: agentId,
      agentName: agentName,
      billDate: billDate,
      fishEntries: fishEntries.map((e) => e.toEntity()).toList(),
      totalWeight: totalWeight,
      totalAmount: totalAmount,
      commissionAmount: commissionAmount,
      netAmount: netAmount,
      status: status,
      notes: notes,
      createdAt: createdAt,
    );
  }
}

// ✅ FishEntryModel
class FishEntryModel {
  final String fishId;
  final String fishName;
  final double weight;
  final double rate;
  final double amount;

  FishEntryModel({
    required this.fishId,
    required this.fishName,
    required this.weight,
    required this.rate,
    required this.amount,
  });

  factory FishEntryModel.fromJson(Map<String, dynamic> json) {
    String fishId = '';
    final fishData = json['fishId'];
    if (fishData is Map<String, dynamic>) {
      fishId = fishData['_id']?.toString() ?? '';
    } else if (fishData is String) {
      fishId = fishData;
    }

    return FishEntryModel(
      fishId: fishId,
      fishName: json['fishName']?.toString() ?? '',
      weight: (json['weightKg'] ?? json['weight'] ?? 0).toDouble(),
      rate: (json['pricePerKg'] ?? json['rate'] ?? 0).toDouble(),
      amount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
  FishEntryEntity toEntity() {
    return FishEntryEntity(
      fishId: fishId,
      fishName: fishName,
      weight: weight,
      rate: rate,
      amount: amount,
    );
  }
}
