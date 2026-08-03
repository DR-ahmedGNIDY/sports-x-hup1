import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type SportDocument = HydratedDocument<Sport>;

@Schema({ collection: 'sports' })
export class Sport {
  @Prop({ required: true, unique: true, trim: true })
  name: string;
}

export const SportSchema = SchemaFactory.createForClass(Sport);
