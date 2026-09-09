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

export class UpsertBannerDto {
  @IsOptional()
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  alt?: LocalizedTextDto;

  // A storefront path only. Constrained to start with a single slash and to
  // carry no scheme or host, so a banner cannot be turned into an open
  // redirect to somewhere off the store.
  @IsOptional()
  @IsString()
  @MaxLength(200)
  @Matches(/^\/(?!\/)[A-Za-z0-9\-._~/]*$/, {
    message:
      'linkPath must be a store path such as /c/men or /p/black-cargo-shorts.',
  })
  linkPath?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
