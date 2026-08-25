import { BadRequestException } from '@nestjs/common';
import { assertFileContentMatchesMimeType } from './file-signature';

function fileWith(mimetype: string, buffer: Buffer): Express.Multer.File {
  return { mimetype, buffer } as Express.Multer.File;
}

const JPEG_HEADER = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0,
]);
const PNG_HEADER = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0,
]);
const GIF_HEADER = Buffer.from('GIF89a' + '\0'.repeat(6));
const WEBP_HEADER = Buffer.concat([
  Buffer.from('RIFF'),
  Buffer.from([0, 0, 0, 0]),
  Buffer.from('WEBP'),
]);
const MP4_HEADER = Buffer.concat([
  Buffer.from([0, 0, 0, 0x18]),
  Buffer.from('ftyp'),
  Buffer.from('isom'),
]);
const WEBM_HEADER = Buffer.from([
  0x1a, 0x45, 0xdf, 0xa3, 0, 0, 0, 0, 0, 0, 0, 0,
]);
const PLAIN_TEXT = Buffer.from('this is just a plain text file, not media');
const ELF_EXECUTABLE = Buffer.from([
  0x7f, 0x45, 0x4c, 0x46, 0, 0, 0, 0, 0, 0, 0, 0,
]);

describe('assertFileContentMatchesMimeType', () => {
  it.each([
    ['image/jpeg', JPEG_HEADER],
    ['image/png', PNG_HEADER],
    ['image/gif', GIF_HEADER],
    ['image/webp', WEBP_HEADER],
  ])('accepts a genuine %s file', (mimetype, buffer) => {
    expect(() =>
      assertFileContentMatchesMimeType(fileWith(mimetype, buffer), 'image'),
    ).not.toThrow();
  });

  it.each([
    ['video/mp4', MP4_HEADER],
    ['video/webm', WEBM_HEADER],
  ])('accepts a genuine %s file', (mimetype, buffer) => {
    expect(() =>
      assertFileContentMatchesMimeType(fileWith(mimetype, buffer), 'video'),
    ).not.toThrow();
  });

  // MIME-spoofing regression: a client can set any Content-Type it wants on
  // a multipart part regardless of the actual bytes (CWE-434). These cases
  // simulate a malicious/executable payload declared as an allowed image or
  // video mimetype.
  it('rejects a plain-text file declared as image/jpeg', () => {
    expect(() =>
      assertFileContentMatchesMimeType(
        fileWith('image/jpeg', PLAIN_TEXT),
        'image',
      ),
    ).toThrow(BadRequestException);
  });

  it('rejects an ELF executable declared as image/png', () => {
    expect(() =>
      assertFileContentMatchesMimeType(
        fileWith('image/png', ELF_EXECUTABLE),
        'image',
      ),
    ).toThrow(BadRequestException);
  });

  it('rejects an ELF executable declared as video/mp4', () => {
    expect(() =>
      assertFileContentMatchesMimeType(
        fileWith('video/mp4', ELF_EXECUTABLE),
        'video',
      ),
    ).toThrow(BadRequestException);
  });

  it('rejects a genuine image whose bytes do not match its declared subtype', () => {
    // PNG bytes declared as image/jpeg — same family, wrong signature.
    expect(() =>
      assertFileContentMatchesMimeType(
        fileWith('image/jpeg', PNG_HEADER),
        'image',
      ),
    ).toThrow(BadRequestException);
  });

  it('rejects a buffer shorter than any known signature', () => {
    expect(() =>
      assertFileContentMatchesMimeType(
        fileWith('image/jpeg', Buffer.from([0xff, 0xd8])),
        'image',
      ),
    ).toThrow(BadRequestException);
  });
});
