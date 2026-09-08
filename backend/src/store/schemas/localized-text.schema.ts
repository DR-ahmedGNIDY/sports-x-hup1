import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

/// Every customer-facing string in the store is stored in both languages at
/// once rather than in a parallel translations collection. The store front
/// is bilingual by default (the app already ships ar/en l10n), so a product
/// with only one language filled in is the exception worth surfacing — not
/// the norm worth designing a join for.
///
/// `en` is required and `ar` is not: a product can go live in English and
/// pick up its Arabic copy later, and the mapper falls back rather than
/// rendering an empty name.
@Schema({ _id: false, timestamps: false })
export class LocalizedText {
  @Prop({ required: true, trim: true })
  en: string;

  @Prop({ trim: true })
  ar?: string;
}

export const LocalizedTextSchema = SchemaFactory.createForClass(LocalizedText);
