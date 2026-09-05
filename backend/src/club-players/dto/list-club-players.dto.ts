import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class ListClubPlayersDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  sport?: string;

  @IsOptional()
  @IsString()
  position?: string;

  // Exact birth year (e.g. 2010) — how clubs group players into age
  // categories ("مواليد 2010"), rather than the min/max-age range the
  // public search endpoint uses.
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1900)
  birthYear?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
