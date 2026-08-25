// lib/features/invoice_template/domain/entities/invoice_template_entity.dart
class InvoiceTemplateEntity {
  final String? id;
  final String title;
  final String subtitle;
  final String termsConditions;
  final ContactDetails contactDetails;
  final Address address;
  final String footer;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceTemplateEntity({
    this.id,
    required this.title,
    required this.subtitle,
    required this.termsConditions,
    required this.contactDetails,
    required this.address,
    required this.footer,
    required this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceTemplateEntity.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplateEntity(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? 'INVOICE',
      subtitle: json['subtitle'] ?? 'Fish Market - Official Receipt',

      termsConditions: json['termsConditions'] ?? '',
      contactDetails: ContactDetails.fromJson(json['contactDetails'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
      footer: json['footer'] ?? 'Thank you for your business!',
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] is Map
          ? (json['createdBy']['name'] ?? json['createdBy']['_id'] ?? '').toString()
          : json['createdBy']?.toString(),
      updatedBy: json['updatedBy'] is Map
          ? (json['updatedBy']['name'] ?? json['updatedBy']['_id'] ?? '').toString()
          : json['updatedBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'termsConditions': termsConditions,
      'contactDetails': contactDetails.toJson(),
      'address': address.toJson(),
      'footer': footer,
      'isActive': isActive,
    };
  }

  String get formattedAddress => address.formatted;
  String get formattedContact => contactDetails.formatted;
}

class ContactDetails {
  final String phone;
  final String email;
  final String website;

  ContactDetails({
    required this.phone,
    required this.email,
    required this.website,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'email': email, 'website': website};
  }

  String get formatted {
    String result = 'Phone: $phone';
    if (email.isNotEmpty) result += ' | Email: $email';
    if (website.isNotEmpty) result += ' | Web: $website';
    return result;
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
    };
  }

  String get formatted {
    return '$street, $city, $state - $pincode, $country';
  }
}
