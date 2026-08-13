import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

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

  @IsOptional()
  @IsString()
  @MaxLength(100)
  level?: string;
}
