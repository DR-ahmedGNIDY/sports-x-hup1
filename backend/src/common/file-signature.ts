import { BadRequestException } from '@nestjs/common';

/**
 * Validates uploaded file *content* against its declared MIME type by
 * checking the file's magic bytes, rather than trusting the client-supplied
 * `Content-Type` (which is only a request header and can be spoofed).
 * CWE-434 (Unrestricted Upload of File with Dangerous Type) — this is the
 * defense-in-depth layer beyond the extension/MIME allowlist already
 * enforced by common/upload.config.ts's Multer `fileFilter`.
 *
 * Deliberately checks by *category* (image/video) rather than pinning an
 * exact codec/container subtype: MP4 and QuickTime share the same
 * ISO-BMFF box structure, so distinguishing them by signature alone is
 * unreliable and would risk false rejections of genuine files. The goal
 * here is to block content that isn't actually the declared media family
 * at all (e.g. an executable or script renamed to `photo.jpg`), not to
 * re-implement a full container-format parser.
 */

function matchesImageSignature(buffer: Buffer, mimetype: string): boolean {
  if (buffer.length < 12) return false;
  switch (mimetype) {
    case 'image/jpeg':
      return buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
    case 'image/png':
      return buffer
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    case 'image/gif':
      return (
        buffer.subarray(0, 6).toString('ascii') === 'GIF87a' ||
        buffer.subarray(0, 6).toString('ascii') === 'GIF89a'
      );
    case 'image/webp':
      return (
        buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
        buffer.subarray(8, 12).toString('ascii') === 'WEBP'
      );
    default:
      return false;
  }
}

// ISO-BMFF ("box") formats (MP4, QuickTime/MOV) start with a 4-byte box
// size followed by a 4-byte box type at offset 4 — a top-level box type
// belonging to this set is what every real MP4/MOV file starts with.
const ISO_BMFF_BOX_TYPES = new Set([
  'ftyp',
  'moov',
  'mdat',
  'free',
  'skip',
  'wide',
]);

function matchesVideoSignature(buffer: Buffer, mimetype: string): boolean {
  if (buffer.length < 12) return false;
  if (mimetype === 'video/webm') {
    return (
      buffer[0] === 0x1a &&
      buffer[1] === 0x45 &&
      buffer[2] === 0xdf &&
      buffer[3] === 0xa3
    );
  }
  if (mimetype === 'video/mp4' || mimetype === 'video/quicktime') {
    return ISO_BMFF_BOX_TYPES.has(buffer.subarray(4, 8).toString('ascii'));
  }
  return false;
}

export type MediaKind = 'image' | 'video';

/**
 * Throws if `file`'s content doesn't match the media family its (already
 * allowlisted) mimetype claims to be. Call after the existing MIME/size
 * checks, once `file.buffer` is populated (Multer memory storage).
 */
export function assertFileContentMatchesMimeType(
  file: Express.Multer.File,
  kind: MediaKind,
): void {
  const matches =
    kind === 'image'
      ? matchesImageSignature(file.buffer, file.mimetype)
      : matchesVideoSignature(file.buffer, file.mimetype);
  if (!matches) {
    throw new BadRequestException(
      "The uploaded file's content does not match its declared type.",
    );
  }
}
