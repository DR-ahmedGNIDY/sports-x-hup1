import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubPlayersModule } from '../club-players/club-players.module';
import { ClubsModule } from '../clubs/clubs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PlayersModule } from '../players/players.module';
import { UsersModule } from '../users/users.module';
import {
  ClubSubscriptionsController,
  MySubscriptionController,
} from './player-subscriptions.controller';
import { PlayerSubscriptionsScheduler } from './player-subscriptions.scheduler';
import { PlayerSubscriptionsService } from './player-subscriptions.service';
import {
  PlayerSubscription,
  PlayerSubscriptionSchema,
} from './schemas/player-subscription.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PlayerSubscription.name, schema: PlayerSubscriptionSchema },
    ]),
    ClubPlayersModule,
    ClubsModule,
    PlayersModule,
    UsersModule,
    NotificationsModule,
  ],
  controllers: [ClubSubscriptionsController, MySubscriptionController],
  providers: [PlayerSubscriptionsService, PlayerSubscriptionsScheduler],
})
export class PlayerSubscriptionsModule {}
