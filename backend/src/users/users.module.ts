import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  CalendarEvent,
  CalendarEventSchema,
} from '../calendar-events/schemas/calendar-event.schema';
import { ClubAccessModule } from '../club-access/club-access.module';
import {
  ClubManagedPlayer,
  ClubManagedPlayerSchema,
} from '../club-players/schemas/club-managed-player.schema';
import { ClubsModule } from '../clubs/clubs.module';
import {
  ClubCoachInvitation,
  ClubCoachInvitationSchema,
} from '../coach-invitations/schemas/club-coach-invitation.schema';
import { CoachesModule } from '../coaches/coaches.module';
import {
  ClubMembership,
  ClubMembershipSchema,
} from '../invitations/schemas/club-membership.schema';
import {
  ClubPlayerInvitation,
  ClubPlayerInvitationSchema,
} from '../invitations/schemas/club-player-invitation.schema';
import { NotificationsModule } from '../notifications/notifications.module';
import { PlayersModule } from '../players/players.module';
import { PostsModule } from '../posts/posts.module';
import {
  SavedPlayer,
  SavedPlayerSchema,
} from '../saved-players/schemas/saved-player.schema';
import { StoreOrder, StoreOrderSchema } from '../store/schemas/order.schema';
import { VideosModule } from '../videos/videos.module';
import { AccountRelationsCleanupService } from './account-relations-cleanup.service';
import { User, UserSchema } from './schemas/user.schema';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      // Registered directly for AccountRelationsCleanupService — see there
      // for why their owning modules can't be imported instead.
      { name: ClubPlayerInvitation.name, schema: ClubPlayerInvitationSchema },
      { name: ClubMembership.name, schema: ClubMembershipSchema },
      { name: ClubCoachInvitation.name, schema: ClubCoachInvitationSchema },
      { name: ClubManagedPlayer.name, schema: ClubManagedPlayerSchema },
      { name: SavedPlayer.name, schema: SavedPlayerSchema },
      { name: CalendarEvent.name, schema: CalendarEventSchema },
      { name: StoreOrder.name, schema: StoreOrderSchema },
    ]),
    // None of these import UsersModule (or AuthModule, which does), so
    // pulling them in here to cascade-delete a user's data on account
    // deletion doesn't create a circular module dependency.
    PlayersModule,
    ClubsModule,
    VideosModule,
    CoachesModule,
    ClubAccessModule,
    PostsModule,
    NotificationsModule,
  ],
  controllers: [UsersController],
  providers: [UsersService, AccountRelationsCleanupService],
  exports: [UsersService],
})
export class UsersModule {}
