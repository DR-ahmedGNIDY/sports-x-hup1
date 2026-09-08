import { BadRequestException, Injectable } from '@nestjs/common';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { assertFileContentMatchesMimeType } from '../common/file-signature';
import { ALLOWED_IMAGE_MIME_TYPES } from '../common/upload.config';
import { ProductImage } from './schemas/product.schema';

/// Shared by the product and category image endpoints, which do the same
/// three things: prove the file really is an image, hand it to Cloudinary,
/// and give back the pair the schemas store.
///
/// The validation is deliberately repeated here rather than trusted from
/// the Multer interceptor. `imageUploadOptions` filters on the *declared*
/// mimetype, which the client chooses; this reads the file's own magic
/// bytes (CWE-434), the same defence the club-logo and player-media
/// uploads already apply.
@Injectable()
export class StoreImagesService {
  constructor(private readonly cloudinary: CloudinaryService) {}

  async upload(
    file: Express.Multer.File,
    folder: string,
  ): Promise<ProductImage> {
    if (!file) throw new BadRequestException('A file is required.');
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A store image must be one of: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
      );
    }
    assertFileContentMatchesMimeType(file, 'image');

    const uploaded = await this.cloudinary.uploadBuffer(
      file.buffer,
      folder,
      'image',
    );
    return { publicId: uploaded.publicId, secureUrl: uploaded.secureUrl };
  }

  // Best-effort: a Cloudinary asset that outlives its document costs storage,
  // but a failure to delete it must not stop the merchant from removing the
  // image from the product.
  async remove(publicId: string): Promise<void> {
    await this.cloudinary.deleteAsset(publicId, 'image');
  }
}
