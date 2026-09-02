import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { PushService } from './push.service';
import {
  Notification,
  NotificationSchema,
} from './schemas/notification.schema';
import {
  PushSubscription,
  PushSubscriptionSchema,
} from './schemas/push-subscription.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: PushSubscription.name, schema: PushSubscriptionSchema },
    ]),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, PushService],
  // Exported so InvitationsModule can emit. Importing this module gives a
  // producer the service and nothing else — the routes stay owned here.
  exports: [NotificationsService],
})
export class NotificationsModule {}
