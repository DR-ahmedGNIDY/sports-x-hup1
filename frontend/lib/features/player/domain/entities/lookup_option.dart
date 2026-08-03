/// A single entry from the `sports` or `countries` lookup collections.
class LookupOption {
  const LookupOption({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;
}
