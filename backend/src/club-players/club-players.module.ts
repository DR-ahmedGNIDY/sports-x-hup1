import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ClubMembership,
  ClubMembershipSchema,
} from '../invitations/schemas/club-membership.schema';
import { ClubAccessModule } from '../club-access/club-access.module';
import { PlayersModule } from '../players/players.module';
import { UsersModule } from '../users/users.module';
import { ClubPlayersController } from './club-players.controller';
import { ClubPlayersService } from './club-players.service';
import {
  ClubManagedPlayer,
  ClubManagedPlayerSchema,
} from './schemas/club-managed-player.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubManagedPlayer.name, schema: ClubManagedPlayerSchema },
      // Players who joined by accepting an invitation are part of the roster
      // too, even though the club never created their account.
      { name: ClubMembership.name, schema: ClubMembershipSchema },
    ]),
    PlayersModule,
    UsersModule,
    ClubAccessModule,
  ],
  controllers: [ClubPlayersController],
  providers: [ClubPlayersService],
})
export class ClubPlayersModule {}
