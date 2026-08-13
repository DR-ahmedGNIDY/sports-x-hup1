import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Matches,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { PreferredFoot } from '../../players/schemas/player-profile.schema';
import { ContactDetailsDto } from '../../players/dto/contact-details.dto';

export class CreateClubPlayerDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  firstName: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  lastName: string;

  // Local number only — no leading 0, no dial code. The service prefixes
  // it with the dial code resolved from countryIsoCode.
  @IsString()
  @Matches(/^\d{6,14}$/, {
    message: 'phone must be 6-14 digits, without a leading 0 or dial code.',
  })
  phone: string;

  // ISO country code (e.g. "EG") — resolves the dial code and, unless
  // `country` is given explicitly, doubles as the profile's country value.
  @IsString()
  @Length(2, 2)
  countryIsoCode: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  nationality?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  country?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @IsOptional()
  @IsString()
  sport?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  position?: string;

  @IsOptional()
  @IsEnum(PreferredFoot)
  preferredFoot?: PreferredFoot;

  @IsOptional()
  @IsNumber()
  @Min(0)
  height?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  currentStatus?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  currentClub?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  bio?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => ContactDetailsDto)
  contact?: ContactDetailsDto;
}
