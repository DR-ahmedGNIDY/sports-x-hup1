import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { LocalizedTextDto } from '../../dto/localized-text.dto';

export class CreateShippingCityDto {
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  name: LocalizedTextDto;

  // Unique within its governorate, not globally — see ShippingCity.
  @IsString()
  @MaxLength(40)
  @Matches(/^[a-z0-9-]+$/, {
    message: 'code must be lowercase letters, digits and hyphens only.',
  })
  code: string;

  @IsInt()
  @Min(0)
  feeMinor: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

// No `code` here: a city's code is in the URL and, like a zone's, cannot be
// changed once orders may reference it.
export class UpdateShippingCityDto {
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  name: LocalizedTextDto;

  @IsInt()
  @Min(0)
  feeMinor: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}
