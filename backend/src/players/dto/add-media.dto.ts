import { IsEnum, IsOptional } from 'class-validator';
import { MediaType } from '../schemas/player-profile.schema';

export class AddMediaDto {
  // Optional so an older client that posts only the file part still works;
  // it lands on PHOTO, which is what that client could only ever have sent.
  @IsOptional()
  @IsEnum(MediaType)
  type?: MediaType;
}
