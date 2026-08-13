import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { VideoVisibility } from '../schemas/video.schema';

export class UploadVideoDto {
  @IsString()
  @IsNotEmpty()
  category: string;

  @IsEnum(VideoVisibility)
  visibility: VideoVisibility;
}
