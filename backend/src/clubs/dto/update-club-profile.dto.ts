import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ClubLevel } from '../club-level.enum';

const MIN_FOUNDED_YEAR = 1800;
const MAX_FOUNDED_YEAR = 2100;

export class UpdateClubProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  name?: string;

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
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(MIN_FOUNDED_YEAR)
  @Max(MAX_FOUNDED_YEAR)
  foundedYear?: number;

  // Controlled values only for new writes — see club-level.enum.ts for why
  // this doesn't also change the schema/storage type.
  @IsOptional()
  @IsEnum(ClubLevel)
  level?: ClubLevel;
}
