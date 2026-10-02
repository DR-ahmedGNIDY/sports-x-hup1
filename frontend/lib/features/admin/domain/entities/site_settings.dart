/// One phone line on the website's contact page.
class SitePhone {
  const SitePhone({required this.label, required this.number});

  final String label;
  final String number;

  factory SitePhone.fromJson(Map<String, dynamic> json) => SitePhone(
    label: json['label'] as String? ?? '',
    number: json['number'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'label': label, 'number': number};
}

/// What the public website (sportxhup.com) shows that the admin edits here:
/// social links, contact details and where to get the app. An empty string
/// means "not set" — the website hides that item.
class SiteSettings {
  const SiteSettings({
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.xUrl = '',
    this.tiktokUrl = '',
    this.youtubeUrl = '',
    this.whatsappNumber = '',
    this.phones = const [],
    this.email = '',
    this.googlePlayUrl = '',
    this.webAppUrl = '',
  });

  final String facebookUrl;
  final String instagramUrl;
  final String xUrl;
  final String tiktokUrl;
  final String youtubeUrl;
  final String whatsappNumber;
  final List<SitePhone> phones;
  final String email;
  final String googlePlayUrl;
  final String webAppUrl;

  factory SiteSettings.fromJson(Map<String, dynamic> json) => SiteSettings(
    facebookUrl: json['facebookUrl'] as String? ?? '',
    instagramUrl: json['instagramUrl'] as String? ?? '',
    xUrl: json['xUrl'] as String? ?? '',
    tiktokUrl: json['tiktokUrl'] as String? ?? '',
    youtubeUrl: json['youtubeUrl'] as String? ?? '',
    whatsappNumber: json['whatsappNumber'] as String? ?? '',
    phones: [
      for (final p in (json['phones'] as List<dynamic>? ?? const []))
        SitePhone.fromJson(p as Map<String, dynamic>),
    ],
    email: json['email'] as String? ?? '',
    googlePlayUrl: json['googlePlayUrl'] as String? ?? '',
    webAppUrl: json['webAppUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'facebookUrl': facebookUrl,
    'instagramUrl': instagramUrl,
    'xUrl': xUrl,
    'tiktokUrl': tiktokUrl,
    'youtubeUrl': youtubeUrl,
    'whatsappNumber': whatsappNumber,
    'phones': [for (final p in phones) p.toJson()],
    'email': email,
    'googlePlayUrl': googlePlayUrl,
    'webAppUrl': webAppUrl,
  };
}
