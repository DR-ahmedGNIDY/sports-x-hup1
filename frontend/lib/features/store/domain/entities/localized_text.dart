/// A customer-facing string in both languages, as the API sends it.
///
/// Both halves travel to the client and the locale picks one at render time,
/// so switching language is instant and costs no round trip — the same
/// reason the backend stores them together rather than resolving server-side.
class LocalizedText {
  const LocalizedText({required this.en, this.ar});

  final String en;
  final String? ar;

  /// The Arabic copy when there is one, English otherwise. A product may go
  /// live in English and pick up its translation later, so falling back is
  /// the normal case, not an error.
  String resolve(bool isArabic) {
    if (!isArabic) return en;
    final arabic = ar;
    if (arabic == null || arabic.isEmpty) return en;
    return arabic;
  }
}
