import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEmail,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

// Every field accepts '' to clear it. `ValidateIf` skips the format check for
// the empty string so clearing a link is not a validation error.
const notEmpty = (_: unknown, value: unknown) => value !== '';

// https only: these are rendered as links on a public page, and a javascript:
// or http: URL there is either an attack or a mixed-content warning.
const HTTPS_URL = { protocols: ['https'], require_protocol: true };

// Digits with an optional leading +, spaces allowed for readability.
const PHONE = /^\+?[0-9 ]{6,20}$/;

export class SitePhoneDto {
  @IsOptional()
  @IsString()
  @MaxLength(40)
  label?: string;

  @IsString()
  @Matches(PHONE, {
    message: 'number must be digits, optionally starting with +.',
  })
  number: string;
}

/// Full replacement of the settings: the admin screen always sends the whole
/// form, so a missing field means "unchanged" and '' means "cleared".
export class UpdateSiteSettingsDto {
  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  facebookUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  instagramUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  xUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  tiktokUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  youtubeUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsString()
  @Matches(PHONE, {
    message: 'whatsappNumber must be digits, optionally starting with +.',
  })
  whatsappNumber?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(6)
  @ValidateNested({ each: true })
  @Type(() => SitePhoneDto)
  phones?: SitePhoneDto[];

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsEmail()
  @MaxLength(120)
  email?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  googlePlayUrl?: string;

  @IsOptional()
  @ValidateIf(notEmpty)
  @IsUrl(HTTPS_URL)
  @MaxLength(300)
  webAppUrl?: string;
}
