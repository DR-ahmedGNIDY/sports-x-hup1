import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ClubProfile,
  ClubProfileSchema,
} from '../clubs/schemas/club-profile.schema';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import {
  PlayerProfile,
  PlayerProfileSchema,
} from '../players/schemas/player-profile.schema';
import { SportsModule } from '../sports/sports.module';
import { User, UserSchema } from '../users/schemas/user.schema';
import { VideosModule } from '../videos/videos.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import {
  PhotoComment,
  PhotoCommentSchema,
} from './schemas/photo-comment.schema';
import { PhotoLike, PhotoLikeSchema } from './schemas/photo-like.schema';
import { PhotoPost, PhotoPostSchema } from './schemas/photo-post.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PhotoPost.name, schema: PhotoPostSchema },
      { name: PhotoLike.name, schema: PhotoLikeSchema },
      { name: PhotoComment.name, schema: PhotoCommentSchema },
      // Registered directly (not via PlayersModule/ClubsModule/UsersModule)
      // purely to read player/club/user data for author and comment
      // resolution — same rationale as VideosModule.
      { name: PlayerProfile.name, schema: PlayerProfileSchema },
      { name: ClubProfile.name, schema: ClubProfileSchema },
      { name: User.name, schema: UserSchema },
    ]),
    CloudinaryModule,
    SportsModule,
    // Exports VideosService so the Home feed can merge in Videos without
    // this module owning/duplicating the Video collection's model.
    VideosModule,
  ],
  controllers: [PostsController],
  providers: [PostsService],
})
export class PostsModule {}
