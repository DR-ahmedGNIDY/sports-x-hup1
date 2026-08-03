import { IsEmail, IsIn, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  // Admin accounts are seeded manually (see PROJECT_ROADMAP.md Phase 4) —
  // self-registration is limited to the two public-facing roles.
  @IsIn(['PLAYER', 'CLUB'])
  role: 'PLAYER' | 'CLUB';
}
