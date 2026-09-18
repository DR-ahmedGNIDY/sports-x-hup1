import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClubAccessService } from '../club-access/club-access.service';
import { ClubsService } from '../clubs/clubs.service';
import { CoachesService } from '../coaches/coaches.service';
import { ProfileVisibility } from '../players/schemas/player-profile.schema';
import { UserRole } from '../users/schemas/user.schema';
import {
  coachSummary,
  toCoachClubView,
  toStaffMemberView,
} from './coach-invitations.mapper';
import { SetCoachPermissionsDto } from './dto/coach-invitation.dto';

// Both ends of a coach's staff membership: the club managing its coaches
// (list, permissions, remove — club account only, never delegable), and a
// coach listing or leaving their clubs.
@Controller()
export class CoachStaffController {
  constructor(
    private readonly access: ClubAccessService,
    private readonly clubsService: ClubsService,
    private readonly coachesService: CoachesService,
  ) {}

  // ------------------------------------------------------------ club side

  @Get('club/coaches')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  async staff(@CurrentUser() user: JwtPayload) {
    const memberships = await this.access.listActiveForClub(user.sub);
    const coaches = await this.coachesService.findManyByUserIds(
      memberships.map((m) => m.coachUserId.toString()),
    );
    const byUserId = new Map(coaches.map((c) => [c.userId.toString(), c]));
    return {
      items: memberships.map((m) =>
        toStaffMemberView(m, byUserId.get(m.coachUserId.toString()) ?? null),
      ),
    };
  }

  @Patch('club/coaches/:membershipId/permissions')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  async setPermissions(
    @CurrentUser() user: JwtPayload,
    @Param('membershipId') membershipId: string,
    @Body() dto: SetCoachPermissionsDto,
  ) {
    const membership = await this.access.setPermissions(
      user.sub,
      membershipId,
      dto.permissions,
    );
    const coach = await this.coachesService.findByUserId(
      membership.coachUserId.toString(),
    );
    return toStaffMemberView(membership, coach);
  }

  @Delete('club/coaches/:membershipId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeCoach(
    @CurrentUser() user: JwtPayload,
    @Param('membershipId') membershipId: string,
  ) {
    await this.access.end({ clubUserId: user.sub }, membershipId);
  }

  // ----------------------------------------------------------- coach side

  // What the club switcher lists: every club the coach works for, with the
  // grant they hold there.
  @Get('coaches/me/clubs')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async myClubs(@CurrentUser() user: JwtPayload) {
    const memberships = await this.access.listActiveForCoach(user.sub);
    const clubs = await this.clubsService.findManyByUserIds(
      memberships.map((m) => m.clubUserId.toString()),
    );
    const byUserId = new Map(clubs.map((c) => [c.userId.toString(), c]));
    return {
      items: memberships.map((m) =>
        toCoachClubView(m, byUserId.get(m.clubUserId.toString()) ?? null),
      ),
    };
  }

  @Delete('coaches/me/clubs/:membershipId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  @HttpCode(HttpStatus.NO_CONTENT)
  async leaveClub(
    @CurrentUser() user: JwtPayload,
    @Param('membershipId') membershipId: string,
  ) {
    await this.access.end({ coachUserId: user.sub }, membershipId);
  }

  // --------------------------------------------------------------- public

  // A club's public staff list. PUBLIC coaches only — being on a staff is
  // not a way around a coach's visibility setting.
  @Get('memberships/clubs/:clubId/coaches')
  async publicStaff(@Param('clubId') clubId: string) {
    const club = await this.clubsService.findByIdOrThrow(clubId);
    const memberships = await this.access.listActiveForClub(
      club.userId.toString(),
    );
    const coaches = await this.coachesService.findManyByUserIds(
      memberships.map((m) => m.coachUserId.toString()),
    );
    return {
      items: coaches
        .filter((c) => c.visibility === ProfileVisibility.PUBLIC)
        .map(coachSummary),
    };
  }
}
