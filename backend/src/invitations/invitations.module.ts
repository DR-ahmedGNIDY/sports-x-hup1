import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ClubManagedPlayer,
  ClubManagedPlayerSchema,
} from '../club-players/schemas/club-managed-player.schema';
import { ClubsModule } from '../clubs/clubs.module';
import { PlayersModule } from '../players/players.module';
import { InvitationsController } from './invitations.controller';
import { InvitationsService } from './invitations.service';
import { MembershipsService } from './memberships.service';
import {
  ClubMembership,
  ClubMembershipSchema,
} from './schemas/club-membership.schema';
import {
  ClubPlayerInvitation,
  ClubPlayerInvitationSchema,
} from './schemas/club-player-invitation.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubPlayerInvitation.name, schema: ClubPlayerInvitationSchema },
      { name: ClubMembership.name, schema: ClubMembershipSchema },
      // Registered directly (the same pattern PlayersModule already uses for
      // SavedPlayer) rather than importing ClubPlayersModule: this feature
      // only reads the ownership row as a business-rule guard, and importing
      // the whole module for one read would couple two independent features.
      { name: ClubManagedPlayer.name, schema: ClubManagedPlayerSchema },
    ]),
    PlayersModule,
    ClubsModule,
  ],
  controllers: [InvitationsController],
  providers: [InvitationsService, MembershipsService],
  // Exported for the Phase 2/3 screens that will read a club's roster and a
  // player's current club.
  exports: [MembershipsService],
})
export class InvitationsModule {}
