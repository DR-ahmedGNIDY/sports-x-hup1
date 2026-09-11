import { Matches } from 'class-validator';

export class ListCalendarEventsDto {
  // 'YYYY-MM' — the visible month for the calendar grid.
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, {
    message: 'month must be in YYYY-MM format.',
  })
  month: string;
}
