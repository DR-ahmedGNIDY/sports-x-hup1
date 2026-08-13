import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type SkillCategoryDocument = HydratedDocument<SkillCategory>;

@Schema({ collection: 'skillcategories' })
export class SkillCategory {
  @Prop({ required: true, trim: true, index: true })
  sport: string;

  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ default: 0 })
  order: number;
}

export const SkillCategorySchema = SchemaFactory.createForClass(SkillCategory);

// Prevents the same category name being seeded/created twice under one sport.
SkillCategorySchema.index({ sport: 1, name: 1 }, { unique: true });
