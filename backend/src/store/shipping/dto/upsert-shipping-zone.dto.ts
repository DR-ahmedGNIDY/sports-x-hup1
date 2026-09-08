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

export class UpsertShippingZoneDto {
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  name: LocalizedTextDto;

  // Constrained to a slug shape because orders store this verbatim and the
  // front end matches on it; spaces and punctuation here would surface as
  // encoding bugs at checkout rather than as a validation error now.
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
