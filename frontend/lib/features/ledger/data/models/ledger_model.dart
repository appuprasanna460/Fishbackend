import '../../domain/entities/ledger_entity.dart';

class LedgerModel extends LedgerEntity {
  const LedgerModel({
    required super.id,
    required super.boatId,
    required super.boatNumber,
    required super.boatName,
    required super.type,
    required super.amount,
    required super.runningBalance,
    required super.description,
    super.referenceId,
    super.referenceType,
    required super.date,
    super.createdAt,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    final boat = json['boatId'];
    return LedgerModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      boatId: boat is Map ? boat['_id'] as String? ?? '' : boat as String? ?? '',
      boatNumber: boat is Map ? boat['boatNumber'] as String? ?? '' : '',
      boatName: boat is Map ? boat['boatName'] as String? ?? '' : '',
      type: json['type'] as String? ?? 'CREDIT',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      runningBalance: (json['runningBalance'] as num? ?? 0).toDouble(),
      description: json['description'] as String? ?? '',
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class BoatBalanceModel {
  final String boatId;
  final String boatNumber;
  final String boatName;
  final double totalCredit;
  final double totalDebit;
  final double balance;

  const BoatBalanceModel({
    required this.boatId,
    required this.boatNumber,
    required this.boatName,
    required this.totalCredit,
    required this.totalDebit,
    required this.balance,
  });

  factory BoatBalanceModel.fromJson(Map<String, dynamic> json) {
    return BoatBalanceModel(
      boatId: json['boatId'] as String? ?? '',
      boatNumber: json['boatNumber'] as String? ?? '',
      boatName: json['boatName'] as String? ?? '',
      totalCredit: (json['totalCredit'] as num? ?? 0).toDouble(),
      totalDebit: (json['totalDebit'] as num? ?? 0).toDouble(),
      balance: (json['balance'] as num? ?? 0).toDouble(),
    );
  }
}
