import { IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  // Either an email or a phone number (club-created players log in with
  // their phone as username) — AuthService resolves whichever it is.
  @IsString()
  @IsNotEmpty()
  identifier: string;

  @IsString()
  password: string;
}
