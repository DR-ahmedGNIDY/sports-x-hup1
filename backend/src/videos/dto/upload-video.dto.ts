import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { VideoVisibility } from '../schemas/video.schema';

export class UploadVideoDto {
  @IsString()
  @IsNotEmpty()
  category: string;

  @IsEnum(VideoVisibility)
  visibility: VideoVisibility;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  title?: string;
}
