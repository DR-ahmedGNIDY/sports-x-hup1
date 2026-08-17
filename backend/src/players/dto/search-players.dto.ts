import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { PreferredFoot } from '../schemas/player-profile.schema';

// Query-string params only — every value arrives as a string, so numeric
// filters go through class-transformer's @Type(() => Number) first.
export class SearchPlayersDto {
  // Matches firstName/lastName — see PlayersService.search for the regex.
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minAge?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxAge?: number;

  @IsOptional()
  @IsString()
  position?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minHeight?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxHeight?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  weight?: number;

  @IsOptional()
  @IsEnum(PreferredFoot)
  preferredFoot?: PreferredFoot;

  @IsOptional()
  @IsString()
  sport?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
