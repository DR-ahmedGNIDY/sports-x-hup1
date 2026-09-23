import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClubsService } from '../clubs/clubs.service';
import { toClubView } from '../clubs/clubs.mapper';
import { PlayersService } from '../players/players.service';
import { PostsService } from '../posts/posts.service';
import { toOwnerView } from '../players/players.mapper';
import { toAdminUser } from '../users/users.mapper';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/schemas/user.schema';
import { PaginationQueryDto } from './dto/pagination-query.dto';
import { SetModeratorDto } from './dto/set-moderator.dto';
import { SetVerifiedDto } from './dto/set-verified.dto';
import { SuspendUserDto } from './dto/suspend-user.dto';
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
    private readonly postsService: PostsService,
  ) {}

  // The dashboard's landing cards — one call rather than making the client
  // fetch and count each list, which would page through the collections
  // just to reach a total.
  @Get('stats')
  async stats() {
    const [userCounts, players, clubs, verifiedClubs, posts, hiddenPosts] =
      await Promise.all([
        this.usersService.countsByRole(),
        this.playersService.countAll(),
        this.clubsService.countAll(),
        this.clubsService.countVerified(),
        this.postsService.countAllPosts(),
        this.postsService.countHiddenPosts(),
      ]);
    return {
      // Accounts, by role. `players`/`clubs` below count *profiles*, which
      // can lag accounts: an account exists from signup, its profile from
      // the first time the user fills anything in.
      ...userCounts,
      playerProfiles: players,
      clubProfiles: clubs,
      verifiedClubs,
      posts,
      hiddenPosts,
    };
  }

  @Get('users')
  async listUsers(@Query() query: PaginationQueryDto) {
    const result = await this.usersService.findAll(query.page ?? 1);
    return { ...result, items: result.items.map(toAdminUser) };
  }

  @Patch('users/:id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
  ) {
    const user = await this.usersService.updateStatus(id, dto.status);
    return toAdminUser(user);
  }

  // Suspends for a fixed term (1 month / 3 months / 1 year) or forever.
  // A fixed-term suspension ends on its own — see
  // `UsersService.liftExpiredSuspension` — so nothing has to remember to
  // come back and undo it.
  @Post('users/:id/suspend')
  async suspendUser(@Param('id') id: string, @Body() dto: SuspendUserDto) {
    const user = await this.usersService.suspend(id, dto.duration, dto.reason);
    return toAdminUser(user);
  }

  @Post('users/:id/reactivate')
  async reactivateUser(@Param('id') id: string) {
    const user = await this.usersService.reactivate(id);
    return toAdminUser(user);
  }

  // Community moderation: lets this user hide or delete Home-feed posts,
  // without making them an admin.
  @Patch('users/:id/moderator')
  async setModerator(@Param('id') id: string, @Body() dto: SetModeratorDto) {
    const user = await this.usersService.setModerator(id, dto.isModerator);
    return toAdminUser(user);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    await this.usersService.deleteById(id);
    return { deleted: true };
  }

  @Get('players')
  async listPlayers(@Query() query: PaginationQueryDto) {
    const result = await this.playersService.findAllForAdmin(query.page ?? 1);
    return { ...result, items: result.items.map(toOwnerView) };
  }

  @Delete('players/:id')
  async deletePlayer(@Param('id') id: string) {
    await this.playersService.deleteProfileAndMedia(id);
    return { deleted: true };
  }

  @Get('clubs')
  async listClubs(@Query() query: PaginationQueryDto) {
    const result = await this.clubsService.findAllForAdmin(query.page ?? 1);
    return { ...result, items: result.items.map(toClubView) };
  }

  // The verification check mark. Public once granted — it renders next to
  // the club's name everywhere, not only here.
  @Patch('clubs/:id/verification')
  async setClubVerification(
    @Param('id') id: string,
    @Body() dto: SetVerifiedDto,
  ) {
    const club = await this.clubsService.setVerification(id, dto.verified);
    return toClubView(club);
  }

  @Delete('clubs/:id')
  async deleteClub(@Param('id') id: string) {
    await this.clubsService.deleteProfileAndLogo(id);
    return { deleted: true };
  }
}
