import { IsEmail, IsIn, IsString, MaxLength, MinLength } from 'class-validator';

// 72 bytes is bcrypt's own input ceiling (it silently truncates beyond
// that), so anything longer buys no extra strength while still costing
// full hashing CPU on every attempt — capping it here rejects oversized
// input before it ever reaches bcrypt (CWE-400).
export const PASSWORD_MAX_LENGTH = 72;

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @MaxLength(PASSWORD_MAX_LENGTH)
  password: string;

  // Admin accounts are seeded manually (see PROJECT_ROADMAP.md Phase 4) —
  // self-registration is limited to the two public-facing roles.
  @IsIn(['PLAYER', 'CLUB'])
  role: 'PLAYER' | 'CLUB';
}
