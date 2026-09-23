import { Module } from '@nestjs/common';
import { ClubsModule } from '../clubs/clubs.module';
import { PlayersModule } from '../players/players.module';
import { PostsModule } from '../posts/posts.module';
import { UsersModule } from '../users/users.module';
import { AdminController } from './admin.controller';

@Module({
  imports: [UsersModule, PlayersModule, ClubsModule, PostsModule],
  controllers: [AdminController],
})
export class AdminModule {}
