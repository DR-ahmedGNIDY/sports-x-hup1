import { IsBoolean, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';

// Video uploads have moved to the dedicated `videos` module (POST /videos).
// This endpoint (POST players/me/media) now only ever accepts a photo, so
// there's no `type` field left to validate — every upload here is a PHOTO.
export class UploadMediaDto {
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isProfilePhoto?: boolean;
}
