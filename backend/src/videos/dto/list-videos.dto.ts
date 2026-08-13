import { IsOptional, IsString } from 'class-validator';

export class ListVideosDto {
  @IsOptional()
  @IsString()
  category?: string;
}
