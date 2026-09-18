import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubsModule } from '../clubs/clubs.module';
import { ClubAccessService } from './club-access.service';
import { ClubActorGuard } from './club-actor.guard';
import {
  ClubCoachMembership,
  ClubCoachMembershipSchema,
} from './schemas/club-coach-membership.schema';

// Shared by every module whose endpoints a coach may use on a club's behalf.
// Depends on ClubsModule only (which depends on no feature module), so any
// feature can import this without creating a cycle.
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubCoachMembership.name, schema: ClubCoachMembershipSchema },
    ]),
    ClubsModule,
  ],
  providers: [ClubAccessService, ClubActorGuard],
  exports: [ClubAccessService, ClubActorGuard],
})
export class ClubAccessModule {}
