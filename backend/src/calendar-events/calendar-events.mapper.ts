import { CalendarEventDocument } from './schemas/calendar-event.schema';

export function toCalendarEventView(event: CalendarEventDocument) {
  return {
    id: event._id.toString(),
    clubUserId: event.clubUserId.toString(),
    type: event.type,
    customTypeName: event.customTypeName,
    date: event.date,
    startTime: event.startTime,
    endTime: event.endTime,
    location: event.location,
    recurrence: event.recurrence,
    recurrenceGroupId: event.recurrenceGroupId?.toString(),
    opponentName: event.opponentName,
    rosterBirthYear: event.rosterBirthYear ?? null,
    participants: event.participants.map((p) => ({
      playerId: p.playerId.toString(),
      position: p.position,
    })),
    confirmedAt: event.confirmedAt,
    matchStats: event.matchStats.map((s) => ({
      playerId: s.playerId.toString(),
      goals: s.goals,
      assists: s.assists,
      chancesCreated: s.chancesCreated,
      keyPasses: s.keyPasses,
      keyDefensiveActions: s.keyDefensiveActions,
      saves: s.saves,
    })),
    createdAt: (event as CalendarEventDocument & { createdAt: Date }).createdAt,
    updatedAt: (event as CalendarEventDocument & { updatedAt: Date }).updatedAt,
  };
}
