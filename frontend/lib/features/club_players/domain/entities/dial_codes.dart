/// Mirrors the backend's `dial-codes.ts` — used here only to show a "+20"
/// style prefix next to the phone field as the club picks a country. The
/// backend is the source of truth for the actual normalization.
const Map<String, String> kDialCodes = {
  'EG': '+20',
  'SA': '+966',
  'AE': '+971',
  'QA': '+974',
  'KW': '+965',
  'JO': '+962',
  'MA': '+212',
  'TN': '+216',
  'DZ': '+213',
  'LB': '+961',
  'IQ': '+964',
  'TR': '+90',
  'GB': '+44',
  'FR': '+33',
  'DE': '+49',
  'ES': '+34',
  'IT': '+39',
  'PT': '+351',
  'NL': '+31',
  'BR': '+55',
  'AR': '+54',
  'US': '+1',
};
