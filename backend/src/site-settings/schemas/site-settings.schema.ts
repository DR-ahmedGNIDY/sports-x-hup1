import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type SiteSettingsDocument = HydratedDocument<SiteSettings>;

/// One phone line shown on the website's contact page.
@Schema({ _id: false })
export class SitePhone {
  // Free text the admin picks ("Customer service", "Clubs"); optional because
  // a single number needs no caption.
  @Prop({ trim: true, default: '' })
  label: string;

  // Stored as typed (E.164-ish, e.g. "+201000000000"): the site renders it
  // and builds the tel: link from it, so it is kept, not reformatted.
  @Prop({ required: true, trim: true })
  number: string;
}

export const SitePhoneSchema = SchemaFactory.createForClass(SitePhone);

/// What the public website shows that the admin edits without a deploy:
/// social links, contact numbers and where to get the app.
///
/// A singleton — every read and write targets the one document whose `key`
/// is [SITE_SETTINGS_KEY]. A collection rather than env vars because these
/// change on a marketing whim, not on a release.
@Schema({ timestamps: true, collection: 'sitesettings' })
export class SiteSettings {
  @Prop({ required: true, unique: true })
  key: string;

  // Empty string means "not set": the site hides that icon rather than
  // linking nowhere.
  @Prop({ trim: true, default: '' }) facebookUrl: string;
  @Prop({ trim: true, default: '' }) instagramUrl: string;
  @Prop({ trim: true, default: '' }) xUrl: string;
  @Prop({ trim: true, default: '' }) tiktokUrl: string;
  @Prop({ trim: true, default: '' }) youtubeUrl: string;

  // A number, not a wa.me link — the site builds the link, and the contact
  // page also shows the number itself.
  @Prop({ trim: true, default: '' }) whatsappNumber: string;

  @Prop({ type: [SitePhoneSchema], default: [] })
  phones: SitePhone[];

  @Prop({ trim: true, lowercase: true, default: '' }) email: string;

  @Prop({ trim: true, default: '' }) googlePlayUrl: string;

  // The iOS card on the download page points here.
  @Prop({ trim: true, default: '' }) webAppUrl: string;
}

export const SiteSettingsSchema = SchemaFactory.createForClass(SiteSettings);

export const SITE_SETTINGS_KEY = 'main';
