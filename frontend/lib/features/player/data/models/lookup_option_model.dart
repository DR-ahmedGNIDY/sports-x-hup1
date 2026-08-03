import '../../domain/entities/lookup_option.dart';

extension LookupOptionModel on LookupOption {
  static LookupOption fromJson(Map<String, dynamic> json) {
    return LookupOption(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}
