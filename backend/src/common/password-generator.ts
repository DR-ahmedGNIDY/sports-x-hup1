import { randomInt } from 'node:crypto';

const UPPER = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I/O — avoid visual ambiguity
const LOWER = 'abcdefghijkmnpqrstuvwxyz';
const DIGITS = '23456789';
const SYMBOLS = '!@#$%&*';
const ALL = UPPER + LOWER + DIGITS + SYMBOLS;

function pick(charset: string): string {
  return charset[randomInt(charset.length)];
}

// Used to generate credentials for club-created player accounts — the
// plaintext is only ever returned once (in the create/resend response) and
// never persisted, so it must be strong and shufflable rather than memorable.
export function generateStrongPassword(length = 12): string {
  const required = [pick(UPPER), pick(LOWER), pick(DIGITS), pick(SYMBOLS)];
  const rest = Array.from({ length: length - required.length }, () =>
    pick(ALL),
  );
  const chars = [...required, ...rest];

  // Fisher-Yates shuffle so the guaranteed classes aren't always up front.
  for (let i = chars.length - 1; i > 0; i -= 1) {
    const j = randomInt(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}
