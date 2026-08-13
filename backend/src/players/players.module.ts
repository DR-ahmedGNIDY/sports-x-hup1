import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import {
  SavedPlayer,
  SavedPlayerSchema,
} from '../saved-players/schemas/saved-player.schema';
import { VideosModule } from '../videos/videos.module';
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
      // Registered here (not by importing SavedPlayersModule, which already
      // depends on PlayersModule) purely to read the saved-by-clubs count
      // for GET /players/me/stats — avoids a circular module dependency.
      { name: SavedPlayer.name, schema: SavedPlayerSchema },
    ]),
    CloudinaryModule,
    // VideosModule registers its schemas directly rather than importing
    // PlayersModule, so this doesn't create a cycle — needed so a deleted
    // player's videos/likes/comments cascade-delete too (deleteAllForPlayer).
    VideosModule,
  ],
  controllers: [PlayersController],
  providers: [PlayersService],
  exports: [PlayersService],
})
export class PlayersModule {}
