import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubAccessModule } from '../club-access/club-access.module';
import { ClubsModule } from '../clubs/clubs.module';
import { CoachesModule } from '../coaches/coaches.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { CoachInvitationsController } from './coach-invitations.controller';
import { CoachInvitationsService } from './coach-invitations.service';
import { CoachStaffController } from './coach-staff.controller';
import {
  ClubCoachInvitation,
  ClubCoachInvitationSchema,
} from './schemas/club-coach-invitation.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubCoachInvitation.name, schema: ClubCoachInvitationSchema },
    ]),
    ClubAccessModule,
    ClubsModule,
    CoachesModule,
    NotificationsModule,
  ],
  controllers: [CoachInvitationsController, CoachStaffController],
  providers: [CoachInvitationsService],
})
export class CoachInvitationsModule {}
