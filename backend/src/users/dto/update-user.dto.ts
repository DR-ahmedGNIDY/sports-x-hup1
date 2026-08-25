import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { PASSWORD_MAX_LENGTH } from '../../auth/dto/register.dto';

export class UpdateUserDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  // Required together with newPassword when changing password.
  @ValidateIf((dto: UpdateUserDto) => Boolean(dto.newPassword))
  @IsString()
  currentPassword?: string;

  @ValidateIf((dto: UpdateUserDto) => Boolean(dto.currentPassword))
  @IsString()
  @MinLength(8)
  @MaxLength(PASSWORD_MAX_LENGTH)
  newPassword?: string;
}
