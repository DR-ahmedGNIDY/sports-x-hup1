import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum CalendarEventType {
  MATCH = 'MATCH',
  TRAINING = 'TRAINING',
  OTHER = 'OTHER',
}

export enum CalendarEventRecurrence {
  NONE = 'NONE',
  WEEKLY = 'WEEKLY',
  MONTHLY = 'MONTHLY',
}

export type CalendarEventDocument = HydratedDocument<CalendarEvent>;

@Schema({ _id: false, timestamps: false })
export class CalendarEventParticipant {
  @Prop({ type: Types.ObjectId, required: true, ref: 'PlayerProfile' })
  playerId: Types.ObjectId;

  // Free-text, matching PlayerProfile.position — there is no schema enum
  // for position anywhere in this codebase, so this mirrors that.
  @Prop({ trim: true })
  position?: string;
}
export const CalendarEventParticipantSchema = SchemaFactory.createForClass(
  CalendarEventParticipant,
);

@Schema({ _id: false, timestamps: false })
export class CalendarEventMatchStat {
  @Prop({ type: Types.ObjectId, required: true, ref: 'PlayerProfile' })
  playerId: Types.ObjectId;

  @Prop({ default: 0 })
  goals: number;

  @Prop({ default: 0 })
  assists: number;

  @Prop({ default: 0 })
  chancesCreated: number;

  @Prop({ default: 0 })
  keyPasses: number;

  @Prop({ default: 0 })
  keyDefensiveActions: number;

  // Only meaningful for the goalkeeper (resolved client-side via
  // parseFootballPositions on the event position) — stored for anyone who
  // submits it rather than schema-gated, same free-text-driven approach as
  // `position` above.
  @Prop({ default: 0 })
  saves: number;
}
export const CalendarEventMatchStatSchema = SchemaFactory.createForClass(
  CalendarEventMatchStat,
);

// One occurrence of a club event — matches, trainings or other activities.
// Recurring events are materialized at creation time as independent sibling
// documents sharing `recurrenceGroupId`, not expanded from a rule at read
// time (see the plan's decision on this).
@Schema({ timestamps: true, collection: 'calendar_events' })
export class CalendarEvent {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User', index: true })
  clubUserId: Types.ObjectId;

  @Prop({ required: true, enum: CalendarEventType })
  type: CalendarEventType;

  @Prop({ trim: true })
  customTypeName?: string;

  @Prop({ required: true })
  date: Date;

  @Prop({ required: true })
  startTime: string;

  @Prop({ required: true })
  endTime: string;

  @Prop({ required: true, trim: true })
  location: string;

  @Prop({
    required: true,
    enum: CalendarEventRecurrence,
    default: CalendarEventRecurrence.NONE,
  })
  recurrence: CalendarEventRecurrence;

  @Prop({ type: Types.ObjectId })
  recurrenceGroupId?: Types.ObjectId;

  @Prop({ trim: true })
  opponentName?: string;

  // A specific birth year, or null/undefined = "all players" — the pool
  // offered at roster-confirm.
  @Prop({ type: Number, default: null })
  rosterBirthYear?: number | null;

  @Prop({ type: [CalendarEventParticipantSchema], default: [] })
  participants: CalendarEventParticipant[];

  @Prop()
  confirmedAt?: Date;

  @Prop({ type: [CalendarEventMatchStatSchema], default: [] })
  matchStats: CalendarEventMatchStat[];
}

export const CalendarEventSchema = SchemaFactory.createForClass(CalendarEvent);

// Month-grid query: a club's own events in a date range, newest-first day.
CalendarEventSchema.index({ clubUserId: 1, date: 1 });

// A player's own calendar/notification-linked view.
CalendarEventSchema.index({ 'participants.playerId': 1, date: 1 });

CalendarEventSchema.index({ recurrenceGroupId: 1 });
