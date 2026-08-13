import { BadRequestException } from '@nestjs/common';

// International dial codes for the fixed country set seeded in
// database/seed.ts. Country schema only stores the ISO code (e.g. "EG"),
// not a dial code — this static map fills that gap for building phone
// usernames and wa.me links without a schema migration/reseed.
// TODO: fold this into the Country schema (a `dialCode` prop) if the
// country list ever needs to grow past this fixed set.
export const DIAL_CODES: Record<string, string> = {
  EG: '+20',
  SA: '+966',
  AE: '+971',
  QA: '+974',
  KW: '+965',
  JO: '+962',
  MA: '+212',
  TN: '+216',
  DZ: '+213',
  LB: '+961',
  IQ: '+964',
  TR: '+90',
  GB: '+44',
  FR: '+33',
  DE: '+49',
  ES: '+34',
  IT: '+39',
  PT: '+351',
  NL: '+31',
  BR: '+55',
  AR: '+54',
  US: '+1',
};

export function getDialCode(isoCode: string): string {
  const dialCode = DIAL_CODES[isoCode.toUpperCase()];
  if (!dialCode) {
    throw new BadRequestException(`Unsupported country code: ${isoCode}.`);
  }
  return dialCode;
}
