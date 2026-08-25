// lib/features/bookings/domain/entities/booking_entity.dart
class BookingEntity {
  final String id;
  final String bookingNumber;
  final String boatId;
  final String boatName;
  final String boatNumber;
  final String agentId;
  final String agentName;
  final String agentEmail; // ✅ NEW
  final String agentPhone; // ✅ NEW
  final DateTime bookingDate;
  final bool isDeleted;

  BookingEntity({
    required this.id,
    required this.bookingNumber,
    required this.boatId,
    required this.boatName,
    required this.boatNumber,
    required this.agentId,
    required this.agentName,
    this.agentEmail = '',
    this.agentPhone = '',
    required this.bookingDate,
    this.isDeleted = false,
  });

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    return BookingEntity(
      id: json['_id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      boatId: json['boatId']?['_id'] ?? json['boatId'] ?? '',
      boatName: json['boatId']?['boatName'] ?? '',
      boatNumber: json['boatId']?['boatNumber'] ?? '',
      agentId: json['agentId']?['_id'] ?? json['agentId'] ?? '',
      agentName: json['agentId']?['name'] ?? '',
      agentEmail: json['agentId']?['email'] ?? '',
      agentPhone: json['agentId']?['phone'] ?? '',
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'boatId': boatId};
  }
}
