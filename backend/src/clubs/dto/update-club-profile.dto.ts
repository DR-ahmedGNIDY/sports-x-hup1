import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

const MIN_FOUNDED_YEAR = 1800;
const MAX_FOUNDED_YEAR = 2100;

export class UpdateClubProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(MIN_FOUNDED_YEAR)
  @Max(MAX_FOUNDED_YEAR)
  foundedYear?: number;

  @IsOptional()
  @IsString()
  level?: string;
}
