import { BadRequestException } from '@nestjs/common';
import { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';

// Ceiling enforced by Multer itself (memory-safety net against an
// unbounded/repeated large upload exhausting process memory before a file
// ever reaches Cloudinary). Per-media-type caps (tighter than this) are
// enforced in the service layer, where the declared media type is known.
export const UPLOAD_SIZE_CEILING_BYTES = 50 * 1024 * 1024; // 50MB — the video cap

export const ALLOWED_IMAGE_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
];

export const ALLOWED_VIDEO_MIME_TYPES = [
  'video/mp4',
  'video/quicktime',
  'video/webm',
];

export const IMAGE_SIZE_LIMIT_BYTES = 5 * 1024 * 1024; // 5MB
export const VIDEO_SIZE_LIMIT_BYTES = UPLOAD_SIZE_CEILING_BYTES;

/** Multer options for an endpoint that only ever accepts an image (club logo). */
export const imageUploadOptions: MulterOptions = {
  limits: { fileSize: IMAGE_SIZE_LIMIT_BYTES },
  fileFilter: (_req, file, callback) => {
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      callback(
        new BadRequestException(
          `Unsupported file type "${file.mimetype}". Allowed: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
        ),
        false,
      );
      return;
    }
    callback(null, true);
  },
};

/**
 * Multer options for an endpoint that accepts either an image or a video
 * (player media) — the declared media `type` (PHOTO/VIDEO) is a separate
 * body field the service layer cross-checks against the actual mimetype,
 * so this filter only rejects files that are neither.
 */
export const mediaUploadOptions: MulterOptions = {
  limits: { fileSize: UPLOAD_SIZE_CEILING_BYTES },
  fileFilter: (_req, file, callback) => {
    const allowed = [...ALLOWED_IMAGE_MIME_TYPES, ...ALLOWED_VIDEO_MIME_TYPES];
    if (!allowed.includes(file.mimetype)) {
      callback(
        new BadRequestException(
          `Unsupported file type "${file.mimetype}". Allowed: ${allowed.join(', ')}.`,
        ),
        false,
      );
      return;
    }
    callback(null, true);
  },
};
