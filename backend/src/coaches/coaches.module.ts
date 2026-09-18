import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubAccessModule } from '../club-access/club-access.module';
import { ClubsModule } from '../clubs/clubs.module';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { PublicCodesModule } from '../public-codes/public-codes.module';
import { CoachClubsService } from './coach-clubs.service';
import { CoachesController } from './coaches.controller';
import { CoachesService } from './coaches.service';
import {
  CoachProfile,
  CoachProfileSchema,
} from './schemas/coach-profile.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachProfile.name, schema: CoachProfileSchema },
    ]),
    CloudinaryModule,
    PublicCodesModule,
    ClubsModule,
    ClubAccessModule,
  ],
  controllers: [CoachesController],
  providers: [CoachesService, CoachClubsService],
  exports: [CoachesService, CoachClubsService],
})
export class CoachesModule {}
