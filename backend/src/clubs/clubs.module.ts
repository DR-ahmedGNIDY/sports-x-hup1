import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { PublicCodesModule } from '../public-codes/public-codes.module';
import { ClubsController } from './clubs.controller';
import { ClubsService } from './clubs.service';
import { ClubProfile, ClubProfileSchema } from './schemas/club-profile.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubProfile.name, schema: ClubProfileSchema },
    ]),
    CloudinaryModule,
    PublicCodesModule,
  ],
  controllers: [ClubsController],
  providers: [ClubsService],
  exports: [ClubsService],
})
export class ClubsModule {}
