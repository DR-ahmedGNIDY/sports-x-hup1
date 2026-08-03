import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { PlayersController } from './players.controller';
import { PlayersService } from './players.service';
import {
  PlayerProfile,
  PlayerProfileSchema,
} from './schemas/player-profile.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PlayerProfile.name, schema: PlayerProfileSchema },
    ]),
    CloudinaryModule,
  ],
  controllers: [PlayersController],
  providers: [PlayersService],
  exports: [PlayersService],
})
export class PlayersModule {}
