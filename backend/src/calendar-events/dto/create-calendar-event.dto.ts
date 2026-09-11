import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Min,
  ValidateIf,
} from 'class-validator';
import {
  CalendarEventRecurrence,
  CalendarEventType,
} from '../schemas/calendar-event.schema';

const TIME_PATTERN = /^([01]\d|2[0-3]):([0-5]\d)$/;

export class CreateCalendarEventDto {
  @IsEnum(CalendarEventType)
  type: CalendarEventType;

  @ValidateIf((dto) => dto.type === CalendarEventType.OTHER)
  @IsString()
  customTypeName?: string;

  @IsDateString()
  date: string;

  @Matches(TIME_PATTERN, { message: 'startTime must be in HH:mm format.' })
  startTime: string;

  @Matches(TIME_PATTERN, { message: 'endTime must be in HH:mm format.' })
  endTime: string;

  @IsString()
  location: string;

  @IsEnum(CalendarEventRecurrence)
  recurrence: CalendarEventRecurrence;

  @ValidateIf((dto) => dto.type === CalendarEventType.MATCH)
  @IsString()
  opponentName?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1900)
  rosterBirthYear?: number | null;
}
