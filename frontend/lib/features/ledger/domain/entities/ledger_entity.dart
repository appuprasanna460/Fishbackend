class LedgerEntity {
  final String id;
  final String boatId;
  final String boatNumber;
  final String boatName;
  final String type; // CREDIT | DEBIT
  final double amount;
  final double runningBalance;
  final String description;
  final String? referenceId;
  final String? referenceType;
  final DateTime date;
  final DateTime? createdAt;

  const LedgerEntity({
    required this.id,
    required this.boatId,
    required this.boatNumber,
    required this.boatName,
    required this.type,
    required this.amount,
    required this.runningBalance,
    required this.description,
    this.referenceId,
    this.referenceType,
    required this.date,
    this.createdAt,
  });

  bool get isCredit => type == 'CREDIT';
}
