import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type StoreBannerDocument = HydratedDocument<StoreBanner>;

@Schema({ _id: false, timestamps: false })
export class BannerImage {
  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;
}
export const BannerImageSchema = SchemaFactory.createForClass(BannerImage);

/// One slide in the storefront's hero.
///
/// Two images rather than one: a banner composed for a 1440-wide screen has
/// its subject somewhere a phone crop cuts off, and the usual fix — letting
/// `BoxFit.cover` decide — is what makes a hero look accidental. The
/// merchant uploads both, and each viewport gets the one meant for it.
@Schema({ timestamps: true, collection: 'storebanners' })
export class StoreBanner {
  @Prop({ type: BannerImageSchema })
  desktopImage?: BannerImage;

  /// Optional. A banner with only a desktop image still shows on a phone —
  /// a cropped banner beats a missing one — but the dashboard flags it.
  @Prop({ type: BannerImageSchema })
  mobileImage?: BannerImage;

  /// Read out by screen readers, and shown if the image fails to load. A
  /// hero carries the campaign's whole message, so leaving it undescribed
  /// makes the page meaningless to anyone not seeing it.
  @Prop({ type: LocalizedTextSchema })
  alt?: LocalizedText;

  /// Where tapping the banner goes, as a storefront path (`/c/men` or
  /// `/p/black-cargo-shorts`). Stored as a path, not a full URL: the store
  /// is mounted inside the app and its prefix is the client's business, and
  /// an absolute URL here would be an open redirect the merchant could
  /// point anywhere.
  @Prop({ trim: true })
  linkPath?: string;

  @Prop({ default: 0 })
  sortOrder: number;

  @Prop({ default: true, index: true })
  isActive: boolean;
}

export const StoreBannerSchema = SchemaFactory.createForClass(StoreBanner);

// The hero asks for exactly this on every visit to the home page.
StoreBannerSchema.index({ isActive: 1, sortOrder: 1 });
