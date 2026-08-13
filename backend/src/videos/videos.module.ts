import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { ClubProfile, ClubProfileSchema } from '../clubs/schemas/club-profile.schema';
import {
  PlayerProfile,
  PlayerProfileSchema,
} from '../players/schemas/player-profile.schema';
import { SportsModule } from '../sports/sports.module';
import { User, UserSchema } from '../users/schemas/user.schema';
import { VideosController } from './videos.controller';
import { VideosService } from './videos.service';
import { VideoComment, VideoCommentSchema } from './schemas/video-comment.schema';
import { VideoLike, VideoLikeSchema } from './schemas/video-like.schema';
import { Video, VideoSchema } from './schemas/video.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Video.name, schema: VideoSchema },
      { name: VideoLike.name, schema: VideoLikeSchema },
      { name: VideoComment.name, schema: VideoCommentSchema },
      // Registered directly (not via PlayersModule/ClubsModule/UsersModule)
      // purely to read player/club/user data for author and comment
      // resolution — avoids a circular module dependency.
      { name: PlayerProfile.name, schema: PlayerProfileSchema },
      { name: ClubProfile.name, schema: ClubProfileSchema },
      { name: User.name, schema: UserSchema },
    ]),
    CloudinaryModule,
    SportsModule,
  ],
  controllers: [VideosController],
  providers: [VideosService],
  // Exported so PlayersModule/UsersModule can reuse the video cascade-delete
  // helpers (deleteAllForPlayer / deleteUserFootprint) without duplicating
  // this module's Video/VideoLike/VideoComment models.
  exports: [VideosService],
})
export class VideosModule {}
