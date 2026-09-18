import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { imageUploadOptions } from '../common/upload.config';
import { UpdatePlayerProfileDto } from '../players/dto/update-player-profile.dto';
import { toOwnerView } from '../players/players.mapper';
import { ClubActor } from '../club-access/club-access.service';
import {
  ClubActorGuard,
  ClubActorParam,
  ClubPermission,
} from '../club-access/club-actor.guard';
import { CoachPermission } from '../club-access/coach-permission.enum';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { UserRole } from '../users/schemas/user.schema';
import { ClubPlayersService } from './club-players.service';
import { CreateClubPlayerDto } from './dto/create-club-player.dto';
import { ListClubPlayersDto } from './dto/list-club-players.dto';

// A roster row as this actor may see it. The owner view carries the
// player's contact details, which a coach sees only with
// VIEW_PLAYER_CONTACTS — the club account always holds it.
function rosterView(
  profile: PlayerProfileDocument,
  dialCode: string,
  actor: ClubActor,
) {
  const view = { ...toOwnerView(profile), dialCode };
  if (actor.permissions.includes(CoachPermission.VIEW_PLAYER_CONTACTS)) {
    return view;
  }
  return { ...view, contact: {} };
}

// The club and any coach on its staff (X-Club-Id). Reading the squad needs
// only membership; each change is gated by its own permission.
@Controller('club-players')
@UseGuards(JwtAuthGuard, RolesGuard, ClubActorGuard)
@Roles(UserRole.CLUB, UserRole.COACH)
export class ClubPlayersController {
  constructor(private readonly clubPlayersService: ClubPlayersService) {}

  @Post()
  @ClubPermission(CoachPermission.CREATE_PLAYERS)
  async create(
    @ClubActorParam() actor: ClubActor,
    @Body() dto: CreateClubPlayerDto,
  ) {
    const { player, credentials, dialCode } =
      await this.clubPlayersService.createPlayer(
        actor.clubUserId,
        dto,
        actor.actorRole === UserRole.COACH ? actor.actorUserId : undefined,
      );
    // Whoever just created the account has to hand its login to the
    // player, so the contact details come back in full here.
    return { player: { ...toOwnerView(player), dialCode }, credentials };
  }

  @Get()
  async list(
    @ClubActorParam() actor: ClubActor,
    @Query() dto: ListClubPlayersDto,
  ) {
    const result = await this.clubPlayersService.listForClub(
      actor.clubUserId,
      dto,
    );
    return {
      items: result.items.map((row) =>
        rosterView(row.profile, row.dialCode, actor),
      ),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  // Fixed path, must be registered before the dynamic ':playerId' route
  // below — otherwise Nest would match "summary" as a :playerId.
  @Get('summary')
  async summary(@ClubActorParam() actor: ClubActor) {
    const result = await this.clubPlayersService.getSummaryForClub(
      actor.clubUserId,
    );
    return {
      totalPlayers: result.totalPlayers,
      completeProfiles: result.completeProfiles,
      incompleteProfiles: result.incompleteProfiles,
      averageCompletionPercent: result.averageCompletionPercent,
      topMissingFields: result.topMissingFields,
      recentPlayers: result.recentPlayers.map((row) =>
        rosterView(row.profile, row.dialCode, actor),
      ),
    };
  }

  @Get(':playerId')
  async getOne(
    @ClubActorParam() actor: ClubActor,
    @Param('playerId') playerId: string,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.getOneForClub(
      actor.clubUserId,
      playerId,
    );
    return rosterView(profile, dialCode, actor);
  }

  @Patch(':playerId')
  @ClubPermission(CoachPermission.MANAGE_CLUB_PLAYERS)
  async update(
    @ClubActorParam() actor: ClubActor,
    @Param('playerId') playerId: string,
    @Body() dto: UpdatePlayerProfileDto,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.updatePlayer(
      actor.clubUserId,
      playerId,
      dto,
    );
    return rosterView(profile, dialCode, actor);
  }

  @Post(':playerId/photo')
  @ClubPermission(CoachPermission.MANAGE_CLUB_PLAYERS)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async uploadPhoto(
    @ClubActorParam() actor: ClubActor,
    @Param('playerId') playerId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.uploadPhoto(
      actor.clubUserId,
      playerId,
      file,
    );
    return rosterView(profile, dialCode, actor);
  }

  @Delete(':playerId')
  @ClubPermission(CoachPermission.REMOVE_MEMBERS)
  @HttpCode(204)
  async remove(
    @ClubActorParam() actor: ClubActor,
    @Param('playerId') playerId: string,
  ) {
    await this.clubPlayersService.removeFromClub(actor.clubUserId, playerId);
  }

  @Post(':playerId/resend-credentials')
  @ClubPermission(CoachPermission.MANAGE_CLUB_PLAYERS)
  async resendCredentials(
    @ClubActorParam() actor: ClubActor,
    @Param('playerId') playerId: string,
  ) {
    const credentials = await this.clubPlayersService.resendCredentials(
      actor.clubUserId,
      playerId,
    );
    return { credentials };
  }
}
