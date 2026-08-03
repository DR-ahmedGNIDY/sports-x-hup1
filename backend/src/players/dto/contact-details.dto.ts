import { IsEmail, IsOptional, IsString } from 'class-validator';

export class ContactDetailsDto {
  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  whatsapp?: string;
}
