import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PlayersModule } from '../players/players.module';
import { UsersModule } from '../users/users.module';
import { ClubPlayersController } from './club-players.controller';
import { ClubPlayersService } from './club-players.service';
import {
  ClubManagedPlayer,
  ClubManagedPlayerSchema,
} from './schemas/club-managed-player.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ClubManagedPlayer.name, schema: ClubManagedPlayerSchema },
    ]),
    PlayersModule,
    UsersModule,
  ],
  controllers: [ClubPlayersController],
  providers: [ClubPlayersService],
})
export class ClubPlayersModule {}
