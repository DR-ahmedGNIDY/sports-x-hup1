import {
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { toSearchResultView } from '../players/players.mapper';
import { UserRole } from '../users/schemas/user.schema';
import { SavedPlayersService } from './saved-players.service';

@Controller('saved-players')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CLUB)
export class SavedPlayersController {
  constructor(private readonly savedPlayersService: SavedPlayersService) {}

  @Get('me')
  async me(@CurrentUser() user: JwtPayload) {
    const profiles = await this.savedPlayersService.listForClub(user.sub);
    return profiles.map(toSearchResultView);
  }

  @Post(':playerId')
  async save(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
  ) {
    await this.savedPlayersService.save(user.sub, playerId);
    return { saved: true };
  }

  @Delete(':playerId')
  async unsave(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
  ) {
    await this.savedPlayersService.unsave(user.sub, playerId);
    return { saved: false };
  }
}
