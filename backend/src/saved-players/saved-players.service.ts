import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PlayersService } from '../players/players.service';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import {
  SavedPlayer,
  SavedPlayerDocument,
} from './schemas/saved-player.schema';

const DUPLICATE_KEY_ERROR_CODE = 11000;

@Injectable()
export class SavedPlayersService {
  constructor(
    @InjectModel(SavedPlayer.name)
    private readonly savedPlayerModel: Model<SavedPlayer>,
    private readonly playersService: PlayersService,
  ) {}

  async save(
    clubUserId: string,
    playerId: string,
  ): Promise<SavedPlayerDocument> {
    // Confirms the player exists and is public before it can be saved —
    // also stops a Club from probing for private/nonexistent player ids.
    await this.playersService.findPublicByIdOrThrow(playerId);
    try {
      return await this.savedPlayerModel.create({ clubUserId, playerId });
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new ConflictException('You have already saved this player.');
      }
      throw error;
    }
  }

  async unsave(clubUserId: string, playerId: string): Promise<void> {
    const result = await this.savedPlayerModel.deleteOne({
      clubUserId,
      playerId,
    });
    if (result.deletedCount === 0) {
      throw new NotFoundException('You have not saved this player.');
    }
  }

  async listForClub(clubUserId: string): Promise<PlayerProfileDocument[]> {
    const saved = await this.savedPlayerModel
      .find({ clubUserId })
      .sort({ createdAt: -1 });
    const playerIds = saved.map((item) => item.playerId.toString());
    if (playerIds.length === 0) return [];

    // Only PUBLIC profiles come back — if a saved player has since gone
    // private, it silently drops out of the list rather than leaking data.
    const profiles = await this.playersService.findManyPublicByIds(playerIds);
    const profileById = new Map(profiles.map((p) => [p._id.toString(), p]));
    return playerIds
      .map((id) => profileById.get(id))
      .filter((p) => p !== undefined);
  }
}
