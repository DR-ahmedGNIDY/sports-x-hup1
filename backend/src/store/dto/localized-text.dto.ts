import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class LocalizedTextDto {
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  en: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  ar?: string;
}

export class LocalizedBodyDto {
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  en: string;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  ar?: string;
}
