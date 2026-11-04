import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubAccessModule } from '../club-access/club-access.module';
import { ClubPlayersModule } from '../club-players/club-players.module';
import { ClubsModule } from '../clubs/clubs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PlayersModule } from '../players/players.module';
import {
  Tournament,
  TournamentFixture,
  TournamentFixtureSchema,
  TournamentParticipant,
  TournamentParticipantSchema,
  TournamentSchema,
} from './schemas/tournament.schemas';
import {
  ClubTournamentsController,
  MyTournamentsController,
} from './tournaments.controller';
import { TournamentsService } from './tournaments.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Tournament.name, schema: TournamentSchema },
      { name: TournamentParticipant.name, schema: TournamentParticipantSchema },
      { name: TournamentFixture.name, schema: TournamentFixtureSchema },
    ]),
    ClubAccessModule,
    ClubPlayersModule,
    ClubsModule,
    PlayersModule,
    NotificationsModule,
  ],
  controllers: [ClubTournamentsController, MyTournamentsController],
  providers: [TournamentsService],
})
export class TournamentsModule {}
