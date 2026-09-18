import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { MediaType } from '../../players/schemas/player-profile.schema';

export class AddCoachMediaDto {
  @IsOptional()
  @IsEnum(MediaType)
  type?: MediaType;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  caption?: string;
}
