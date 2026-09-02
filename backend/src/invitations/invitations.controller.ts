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
@Controller('invitations')
@UseGuards(JwtAuthGuard, RolesGuard)
export class InvitationsController {
  constructor(private readonly invitationsService: InvitationsService) {}

  @Post('club-to-player')
  @Roles(UserRole.CLUB)
  @Throttle(INVITATION_SEND_THROTTLE)
  async invitePlayer(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateClubToPlayerInvitationDto,
  ) {
    const row = await this.invitationsService.sendClubToPlayer(user.sub, dto);
    return toInvitationView(row, user.sub);
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
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  async received(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListInvitationsDto,
  ) {
    const result = await this.invitationsService.listReceived(user.sub, dto);
    return this.toPageView(result, user.sub);
  }

  @Get('sent')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  async sent(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListInvitationsDto,
  ) {
    const result = await this.invitationsService.listSent(user.sub, dto);
    return this.toPageView(result, user.sub);
  }

  // Fixed path, registered before the ':id' route below so "summary" is never
  // matched as an invitation id.
  @Get('summary')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  summary(@CurrentUser() user: JwtPayload) {
    return this.invitationsService.summary(user.sub);
  }

  @Get(':id')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  async findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitationsService.findByIdForParty(user.sub, id);
    return toInvitationView(row, user.sub);
  }

  @Post(':id/accept')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  @HttpCode(HttpStatus.OK)
  async accept(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitationsService.accept(user.sub, id);
    return toInvitationView(row, user.sub);
  }

  @Post(':id/reject')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  @HttpCode(HttpStatus.OK)
  async reject(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitationsService.reject(user.sub, id);
    return toInvitationView(row, user.sub);
  }

  @Post(':id/cancel')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  @HttpCode(HttpStatus.OK)
  async cancel(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitationsService.cancel(user.sub, id);
    return toInvitationView(row, user.sub);
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
