import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type CounterDocument = HydratedDocument<Counter>;

// One document per sequence (`_id` is the sequence name, e.g. "CLB"), holding
// the last number handed out. Only ever touched through a single atomic
// `findOneAndUpdate($inc, { upsert: true })` — see PublicCodesService — so
// concurrent allocations can't collide on a number.
@Schema({ timestamps: false, collection: 'counters' })
export class Counter {
  @Prop({ type: String, required: true })
  _id: string;

  @Prop({ required: true, default: 0 })
  seq: number;
}

export const CounterSchema = SchemaFactory.createForClass(Counter);
