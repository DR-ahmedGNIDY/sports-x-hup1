import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateVideoTitleDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  title?: string;
}
