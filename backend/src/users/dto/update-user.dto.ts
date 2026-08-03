import {
  IsEmail,
  IsOptional,
  IsString,
  MinLength,
  ValidateIf,
} from 'class-validator';

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
  newPassword?: string;
}
