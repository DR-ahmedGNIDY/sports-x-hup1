import { IsEnum } from 'class-validator';
import { VideoVisibility } from '../schemas/video.schema';

export class UpdateVideoVisibilityDto {
  @IsEnum(VideoVisibility)
  visibility: VideoVisibility;
}
