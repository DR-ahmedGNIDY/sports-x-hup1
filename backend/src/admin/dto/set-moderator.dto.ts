import { IsBoolean } from 'class-validator';

export class SetModeratorDto {
  @IsBoolean()
  isModerator: boolean;
}
