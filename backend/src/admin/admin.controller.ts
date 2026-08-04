import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClubsService } from '../clubs/clubs.service';
import { toClubView } from '../clubs/clubs.mapper';
import { PlayersService } from '../players/players.service';
import { toOwnerView } from '../players/players.mapper';
import { toPublicUser } from '../users/users.mapper';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/schemas/user.schema';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';

// Thin — every handler just calls into Users/Players/Clubs and reuses
// their existing mappers, per the roadmap's "reuses Users, Players, Clubs
// modules behind an admin guard" design.
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(
    private readonly usersService: UsersService,
    private readonly playersService: PlayersService,
    private readonly clubsService: ClubsService,
  ) {}

  @Get('users')
  async listUsers() {
    const users = await this.usersService.findAll();
    return users.map(toPublicUser);
  }

  @Patch('users/:id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
  ) {
    const user = await this.usersService.updateStatus(id, dto.status);
    return toPublicUser(user);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    await this.usersService.deleteById(id);
    return { deleted: true };
  }

  @Get('players')
  async listPlayers() {
    const profiles = await this.playersService.findAllForAdmin();
    return profiles.map(toOwnerView);
  }

  @Delete('players/:id')
  async deletePlayer(@Param('id') id: string) {
    await this.playersService.deleteProfileAndMedia(id);
    return { deleted: true };
  }

  @Get('clubs')
  async listClubs() {
    const profiles = await this.clubsService.findAllForAdmin();
    return profiles.map(toClubView);
  }

  @Delete('clubs/:id')
  async deleteClub(@Param('id') id: string) {
    await this.clubsService.deleteProfileAndLogo(id);
    return { deleted: true };
  }
}
