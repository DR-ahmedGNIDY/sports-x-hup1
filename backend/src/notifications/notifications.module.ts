import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from '../users/schemas/user.schema';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { FcmService } from './fcm.service';
import { PushService } from './push.service';
import {
  DeviceToken,
  DeviceTokenSchema,
} from './schemas/device-token.schema';
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
      { name: DeviceToken.name, schema: DeviceTokenSchema },
      // Read-only here: emitToAdmins looks up who the admins are.
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, PushService, FcmService],
  // Exported so InvitationsModule can emit. Importing this module gives a
  // producer the service and nothing else — the routes stay owned here.
  exports: [NotificationsService],
})
export class NotificationsModule {}
