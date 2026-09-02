/// Public codes — `CLB-000123`, `PLY-000123` — as the user types them.
///
/// The backend normalizes too, so this is not the validation: it is what
/// keeps "ply-000123 " and "PLY-000123" from becoming two cache keys for
/// one player, where the second lookup would spend a request from a tight
/// per-minute budget proving what the first already knew.
String normalizePublicCode(String code) => code.trim().toUpperCase();
