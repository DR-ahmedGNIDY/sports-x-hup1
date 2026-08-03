class ContactDetails {
  const ContactDetails({this.phone, this.email, this.whatsapp});

  final String? phone;
  final String? email;
  final String? whatsapp;

  bool get isEmpty => phone == null && email == null && whatsapp == null;
}
