import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ClubManagedPlayer,
  ClubManagedPlayerSchema,
} from '../club-players/schemas/club-managed-player.schema';
import { ClubsModule } from '../clubs/clubs.module';
import {
  ClubMembership,
  ClubMembershipSchema,
} from '../invitations/schemas/club-membership.schema';
import { NotificationsModule } from '../notifications/notifications.module';
import { PlayersModule } from '../players/players.module';
import { CalendarEventsController } from './calendar-events.controller';
import { CalendarEventsService } from './calendar-events.service';
import {
  CalendarEvent,
  CalendarEventSchema,
} from './schemas/calendar-event.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CalendarEvent.name, schema: CalendarEventSchema },
      // Registered directly rather than importing ClubPlayersModule — this
      // feature only reads the ownership rows to build the roster pool.
      { name: ClubManagedPlayer.name, schema: ClubManagedPlayerSchema },
      // A player who accepted an invitation belongs to the squad just as
      // much as one the club created, so both sources feed the roster pool.
      { name: ClubMembership.name, schema: ClubMembershipSchema },
    ]),
    PlayersModule,
    ClubsModule,
    NotificationsModule,
  ],
  controllers: [CalendarEventsController],
  providers: [CalendarEventsService],
})
export class CalendarEventsModule {}
