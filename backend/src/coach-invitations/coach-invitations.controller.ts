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
import { ListInvitationsDto } from '../invitations/dto/list-invitations.dto';
import { UserRole } from '../users/schemas/user.schema';
import { toCoachInvitationView } from './coach-invitations.mapper';
import {
  CoachInvitationsService,
  HydratedCoachInvitationPage,
} from './coach-invitations.service';
import {
  CreateClubToCoachInvitationDto,
  CreateCoachToClubInvitationDto,
} from './dto/coach-invitation.dto';

// Inviting a coach is the club account's alone — managing staff is one of
// the things no coach permission can grant.
@Controller('coach-invitations')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CoachInvitationsController {
  constructor(private readonly invitations: CoachInvitationsService) {}

  @Post('club-to-coach')
  @Roles(UserRole.CLUB)
  @Throttle(INVITATION_SEND_THROTTLE)
  async inviteCoach(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateClubToCoachInvitationDto,
  ) {
    const row = await this.invitations.sendClubToCoach(user.sub, dto);
    return toCoachInvitationView(row, user.sub);
  }

  @Post('coach-to-club')
  @Roles(UserRole.COACH)
  @Throttle(INVITATION_SEND_THROTTLE)
  async requestToJoin(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateCoachToClubInvitationDto,
  ) {
    const row = await this.invitations.sendCoachToClub(user.sub, dto);
    return toCoachInvitationView(row, user.sub);
  }

  @Get('received')
  @Roles(UserRole.CLUB, UserRole.COACH)
  async received(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListInvitationsDto,
  ) {
    return this.page(
      await this.invitations.listReceived(user.sub, dto),
      user.sub,
    );
  }

  @Get('sent')
  @Roles(UserRole.CLUB, UserRole.COACH)
  async sent(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListInvitationsDto,
  ) {
    return this.page(await this.invitations.listSent(user.sub, dto), user.sub);
  }

  @Get('summary')
  @Roles(UserRole.CLUB, UserRole.COACH)
  summary(@CurrentUser() user: JwtPayload) {
    return this.invitations.summary(user.sub);
  }

  @Get(':id')
  @Roles(UserRole.CLUB, UserRole.COACH)
  async findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitations.findByIdForParty(user.sub, id);
    return toCoachInvitationView(row, user.sub);
  }

  @Post(':id/accept')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @HttpCode(HttpStatus.OK)
  async accept(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitations.accept(user.sub, id);
    return toCoachInvitationView(row, user.sub);
  }

  @Post(':id/reject')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @HttpCode(HttpStatus.OK)
  async reject(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitations.reject(user.sub, id);
    return toCoachInvitationView(row, user.sub);
  }

  @Post(':id/cancel')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @HttpCode(HttpStatus.OK)
  async cancel(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const row = await this.invitations.cancel(user.sub, id);
    return toCoachInvitationView(row, user.sub);
  }

  private page(result: HydratedCoachInvitationPage, viewer: string) {
    return {
      items: result.items.map((row) => toCoachInvitationView(row, viewer)),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }
}
