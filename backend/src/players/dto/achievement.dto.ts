import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

// Upper bound is a sanity cap (not a hard business rule) — keeps obvious
// garbage input like year 9999 out of the database.
const MAX_ACHIEVEMENT_YEAR = 2100;

export class CreateAchievementDto {
  @IsString()
  title: string;

  @IsInt()
  @Min(1900)
  @Max(MAX_ACHIEVEMENT_YEAR)
  year: number;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateAchievementDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsInt()
  @Min(1900)
  @Max(MAX_ACHIEVEMENT_YEAR)
  year?: number;

  @IsOptional()
  @IsString()
  description?: string;
}
