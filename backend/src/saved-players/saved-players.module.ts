import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PlayersModule } from '../players/players.module';
import { SavedPlayersController } from './saved-players.controller';
import { SavedPlayersService } from './saved-players.service';
import { SavedPlayer, SavedPlayerSchema } from './schemas/saved-player.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SavedPlayer.name, schema: SavedPlayerSchema },
    ]),
    PlayersModule,
  ],
  controllers: [SavedPlayersController],
  providers: [SavedPlayersService],
})
export class SavedPlayersModule {}
