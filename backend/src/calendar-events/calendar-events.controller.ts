import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClubActor } from '../club-access/club-access.service';
import {
  ClubActorGuard,
  ClubActorParam,
  ClubPermission,
  OptionalClubActorParam,
} from '../club-access/club-actor.guard';
import { CoachPermission } from '../club-access/coach-permission.enum';
import { UserRole } from '../users/schemas/user.schema';
import { CalendarEventsService } from './calendar-events.service';
import { toCalendarEventView } from './calendar-events.mapper';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto';
import { ListCalendarEventsDto } from './dto/list-calendar-events.dto';
import { UpdateRosterDto } from './dto/update-roster.dto';
import { UpdateStatsDto } from './dto/update-stats.dto';

// Club routes admit the club and any coach on its staff (X-Club-Id); what
// a coach may change is gated per route by @ClubPermission. Reading the
// calendar needs nothing beyond being on the staff.
@Controller('calendar-events')
@UseGuards(JwtAuthGuard, RolesGuard, ClubActorGuard)
export class CalendarEventsController {
  constructor(private readonly calendarEventsService: CalendarEventsService) {}

  @Post()
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.MANAGE_CALENDAR)
  async create(
    @ClubActorParam() actor: ClubActor,
    @Body() dto: CreateCalendarEventDto,
  ) {
    const events = await this.calendarEventsService.create(
      actor.clubUserId,
      dto,
    );
    return { items: events.map(toCalendarEventView) };
  }

  @Get()
  @Roles(UserRole.CLUB, UserRole.COACH)
  async list(
    @ClubActorParam() actor: ClubActor,
    @Query() dto: ListCalendarEventsDto,
  ) {
    const events = await this.calendarEventsService.listForClub(
      actor.clubUserId,
      dto.month,
    );
    return { items: events.map(toCalendarEventView) };
  }

  @Get('mine')
  @Roles(UserRole.PLAYER)
  async mine(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListCalendarEventsDto,
  ) {
    const events = await this.calendarEventsService.listForPlayer(
      user.sub,
      dto.month,
    );
    return { items: events.map(toCalendarEventView) };
  }

  @Get(':id/roster-pool')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.MANAGE_LINEUP)
  async rosterPool(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
  ) {
    const groups = await this.calendarEventsService.rosterPool(
      actor.clubUserId,
      id,
    );
    return {
      groups: groups.map((group) => ({
        birthYear: group.birthYear,
        players: group.players.map((p) => ({
          id: p._id.toString(),
          firstName: p.firstName,
          lastName: p.lastName,
          position: p.position,
          dateOfBirth: p.dateOfBirth,
        })),
      })),
    };
  }

  @Patch(':id/roster')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.MANAGE_LINEUP)
  async updateRoster(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Body() dto: UpdateRosterDto,
  ) {
    const event = await this.calendarEventsService.updateRoster(
      actor.clubUserId,
      id,
      dto,
    );
    return toCalendarEventView(event);
  }

  @Get(':id')
  @Roles(UserRole.CLUB, UserRole.COACH, UserRole.PLAYER)
  async findOne(
    @CurrentUser() user: JwtPayload,
    @OptionalClubActorParam() actor: ClubActor | undefined,
    @Param('id') id: string,
  ) {
    const event = actor
      ? await this.calendarEventsService.findByIdForParty(
          actor.clubUserId,
          id,
          'CLUB',
        )
      : await this.calendarEventsService.findByIdForParty(
          user.sub,
          id,
          'PLAYER',
        );
    return toCalendarEventView(event);
  }

  @Patch(':id/stats')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.MANAGE_LINEUP)
  async updateStats(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Body() dto: UpdateStatsDto,
  ) {
    const event = await this.calendarEventsService.updateStats(
      actor.clubUserId,
      id,
      dto,
    );
    return toCalendarEventView(event);
  }

  @Delete(':id')
  @Roles(UserRole.CLUB, UserRole.COACH)
  @ClubPermission(CoachPermission.MANAGE_CALENDAR)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@ClubActorParam() actor: ClubActor, @Param('id') id: string) {
    await this.calendarEventsService.remove(actor.clubUserId, id);
  }
}
