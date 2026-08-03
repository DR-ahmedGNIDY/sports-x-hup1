import { IsEnum } from 'class-validator';
import { ProfileVisibility } from '../schemas/player-profile.schema';

export class UpdateVisibilityDto {
  @IsEnum(ProfileVisibility)
  visibility: ProfileVisibility;
}
