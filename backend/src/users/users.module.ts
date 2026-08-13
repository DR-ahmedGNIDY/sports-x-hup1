import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClubsModule } from '../clubs/clubs.module';
import { PlayersModule } from '../players/players.module';
import { VideosModule } from '../videos/videos.module';
import { User, UserSchema } from './schemas/user.schema';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    // None of these import UsersModule (or AuthModule, which does), so
    // pulling them in here to cascade-delete a user's profile/videos on
    // admin delete-user doesn't create a circular module dependency.
    PlayersModule,
    ClubsModule,
    VideosModule,
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
