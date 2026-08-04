import '../../domain/entities/contact_details.dart';

extension ContactDetailsModel on ContactDetails {
  static ContactDetails fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContactDetails();
    return ContactDetails(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      whatsapp: json['whatsapp'] as String?,
    );
  }
}
