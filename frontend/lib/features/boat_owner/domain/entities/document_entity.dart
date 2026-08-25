class DocumentEntity {
  final String? id;
  final String ownerId;
  final String documentName;
  final String documentNumber;
  final String? boatId;
  final String? crewMemberId;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuedBy;
  final List<DocumentFileEntity> files;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Virtual fields populated by backend virtuals or computed locally
  final int remainingDays;
  final String status; // 'Valid' | 'Expiring Soon' | 'Expired'

  DocumentEntity({
    this.id,
    required this.ownerId,
    required this.documentName,
    required this.documentNumber,
    this.boatId,
    this.crewMemberId,
    required this.issueDate,
    required this.expiryDate,
    required this.issuedBy,
    required this.files,
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    required this.remainingDays,
    required this.status,
  });

  factory DocumentEntity.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List? ?? [];
    List<DocumentFileEntity> parsedFiles = filesList
        .map((f) => DocumentFileEntity.fromJson(f as Map<String, dynamic>))
        .toList();

    // Parse issueDate and expiryDate
    DateTime parsedIssueDate = json['issueDate'] != null
        ? DateTime.parse(json['issueDate'])
        : DateTime.now();
    DateTime parsedExpiryDate = json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'])
        : DateTime.now();

    // Resolving boatId and crewMemberId which might be populated objects
    String? bId;
    if (json['boatId'] != null) {
      if (json['boatId'] is Map<String, dynamic>) {
        bId = json['boatId']['_id']?.toString();
      } else {
        bId = json['boatId']?.toString();
      }
    }

    String? cId;
    if (json['crewMemberId'] != null) {
      if (json['crewMemberId'] is Map<String, dynamic>) {
        cId = json['crewMemberId']['_id']?.toString();
      } else {
        cId = json['crewMemberId']?.toString();
      }
    }

    return DocumentEntity(
      id: json['_id'],
      ownerId: json['ownerId'] ?? '',
      documentName: json['documentName'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      boatId: bId,
      crewMemberId: cId,
      issueDate: parsedIssueDate,
      expiryDate: parsedExpiryDate,
      issuedBy: json['issuedBy'] ?? '',
      files: parsedFiles,
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      remainingDays: json['remainingDays'] ?? 0,
      status: json['status'] ?? 'Expired',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'ownerId': ownerId,
      'documentName': documentName,
      'documentNumber': documentNumber,
      if (boatId != null) 'boatId': boatId,
      if (crewMemberId != null) 'crewMemberId': crewMemberId,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'issuedBy': issuedBy,
      'files': files.map((f) => f.toJson()).toList(),
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }
}

class DocumentFileEntity {
  final String url;
  final String key;
  final String? originalName;
  final String? mimeType;
  final int? sizeBytes;

  DocumentFileEntity({
    required this.url,
    required this.key,
    this.originalName,
    this.mimeType,
    this.sizeBytes,
  });

  factory DocumentFileEntity.fromJson(Map<String, dynamic> json) {
    return DocumentFileEntity(
      url: json['url'] ?? '',
      key: json['key'] ?? '',
      originalName: json['originalName'],
      mimeType: json['mimeType'],
      sizeBytes: json['sizeBytes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'key': key,
      if (originalName != null) 'originalName': originalName,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
    };
  }
}
