import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { INVITATION_SEND_THROTTLE } from '../common/throttle.config';
import { ClubActor } from '../club-access/club-access.service';
import {
  ClubActorGuard,
  ClubPermission,
  OptionalClubActorParam,
} from '../club-access/club-actor.guard';
import { CoachPermission } from '../club-access/coach-permission.enum';
import { UserRole } from '../users/schemas/user.schema';
import {
  CreateClubToPlayerInvitationDto,
  CreatePlayerToClubInvitationDto,
} from './dto/create-invitation.dto';
import { ListInvitationsDto } from './dto/list-invitations.dto';
import { toInvitationView } from './invitations.mapper';
import {
  HydratedInvitationPage,
  InvitationsService,
} from './invitations.service';

// Every route here is authenticated. ADMIN is deliberately absent from the
// @Roles lists: an admin account is neither a club nor a player, so it has no
// inbox, no outbox and nothing to accept — moderation of invitations is not
// part of this feature.
// A coach with INVITE_PLAYERS works this inbox *as the club* (X-Club-Id):
// every call below runs with the club's user id, so the club's invitations
// are exactly what the coach sees and acts on. Players are unaffected — the
// guard passes them through and the permission never applies to them.
@Controller('invitations')
@UseGuards(JwtAuthGuard, RolesGuard, ClubActorGuard)
export class InvitationsController {
  constructor(private readonly invitationsService: InvitationsService) {}

  private partyId(user: JwtPayload, actor: ClubActor | undefined): string {
    return actor?.clubUserId ?? user.sub;
  }

  @Post('club-to-player')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  @Throttle(INVITATION_SEND_THROTTLE)
  async invitePlayer(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Body() dto: CreateClubToPlayerInvitationDto,
  ) {
    const clubUserId = this.partyId(user, actor);
    const row = await this.invitationsService.sendClubToPlayer(clubUserId, dto);
    return toInvitationView(row, clubUserId);
  }

  @Post('player-to-club')
  @Roles(UserRole.PLAYER)
  @Throttle(INVITATION_SEND_THROTTLE)
  async requestToJoinClub(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePlayerToClubInvitationDto,
  ) {
    const row = await this.invitationsService.sendPlayerToClub(user.sub, dto);
    return toInvitationView(row, user.sub);
  }

  @Get('received')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  async received(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Query() dto: ListInvitationsDto,
  ) {
    const party = this.partyId(user, actor);
    const result = await this.invitationsService.listReceived(party, dto);
    return this.toPageView(result, party);
  }

  @Get('sent')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  async sent(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Query() dto: ListInvitationsDto,
  ) {
    const party = this.partyId(user, actor);
    const result = await this.invitationsService.listSent(party, dto);
    return this.toPageView(result, party);
  }

  // Fixed path, registered before the ':id' route below so "summary" is never
  // matched as an invitation id.
  @Get('summary')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  summary(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
  ) {
    return this.invitationsService.summary(this.partyId(user, actor));
  }

  @Get(':id')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  async findOne(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Param('id') id: string,
  ) {
    const party = this.partyId(user, actor);
    const row = await this.invitationsService.findByIdForParty(party, id);
    return toInvitationView(row, party);
  }

  @Post(':id/accept')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  @HttpCode(HttpStatus.OK)
  async accept(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Param('id') id: string,
  ) {
    const party = this.partyId(user, actor);
    const row = await this.invitationsService.accept(party, id);
    return toInvitationView(row, party);
  }

  @Post(':id/reject')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  @HttpCode(HttpStatus.OK)
  async reject(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Param('id') id: string,
  ) {
    const party = this.partyId(user, actor);
    const row = await this.invitationsService.reject(party, id);
    return toInvitationView(row, party);
  }

  @Post(':id/cancel')
  @Roles(UserRole.CLUB, UserRole.PLAYER, UserRole.COACH)
  @ClubPermission(CoachPermission.INVITE_PLAYERS)
  @HttpCode(HttpStatus.OK)
  async cancel(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Param('id') id: string,
  ) {
    const party = this.partyId(user, actor);
    const row = await this.invitationsService.cancel(party, id);
    return toInvitationView(row, party);
  }

  private toPageView(result: HydratedInvitationPage, viewerUserId: string) {
    return {
      items: result.items.map((row) => toInvitationView(row, viewerUserId)),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }
}
