import { BadRequestException } from '@nestjs/common';
import { CloudinaryResourceType } from '../cloudinary/cloudinary.service';
import { MediaType } from '../players/schemas/player-profile.schema';
import { assertFileContentMatchesMimeType } from './file-signature';
import {
  ALLOWED_IMAGE_MIME_TYPES,
  ALLOWED_VIDEO_MIME_TYPES,
  IMAGE_SIZE_LIMIT_BYTES,
  VIDEO_SIZE_LIMIT_BYTES,
} from './upload.config';

// Shared by every profile that keeps a photo/video album (players, coaches).

export function resourceTypeFor(type: MediaType): CloudinaryResourceType {
  return type === MediaType.VIDEO ? 'video' : 'image';
}

// The upload interceptor's fileFilter (upload.config.ts) only rejects files
// that are neither an allowed image nor an allowed video type — it can't
// know which one the caller *declared* via the `type` field, since that's a
// separate multipart field, not the file part. This closes that gap: a
// PHOTO upload must actually be an image (and within the tighter photo size
// cap), a VIDEO upload must actually be a video.
export function validateMediaFile(
  type: MediaType,
  file: Express.Multer.File,
): void {
  if (type === MediaType.PHOTO) {
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A PHOTO upload must be one of: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
      );
    }
    if (file.size > IMAGE_SIZE_LIMIT_BYTES) {
      throw new BadRequestException(
        `Photo exceeds the ${IMAGE_SIZE_LIMIT_BYTES / (1024 * 1024)}MB limit.`,
      );
    }
    assertFileContentMatchesMimeType(file, 'image');
    return;
  }
  if (!ALLOWED_VIDEO_MIME_TYPES.includes(file.mimetype)) {
    throw new BadRequestException(
      `A VIDEO upload must be one of: ${ALLOWED_VIDEO_MIME_TYPES.join(', ')}.`,
    );
  }
  if (file.size > VIDEO_SIZE_LIMIT_BYTES) {
    throw new BadRequestException(
      `Video exceeds the ${VIDEO_SIZE_LIMIT_BYTES / (1024 * 1024)}MB limit.`,
    );
  }
  assertFileContentMatchesMimeType(file, 'video');
}
