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
import { UserRole } from '../users/schemas/user.schema';
import { CalendarEventsService } from './calendar-events.service';
import { toCalendarEventView } from './calendar-events.mapper';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto';
import { ListCalendarEventsDto } from './dto/list-calendar-events.dto';
import { UpdateRosterDto } from './dto/update-roster.dto';
import { UpdateStatsDto } from './dto/update-stats.dto';

@Controller('calendar-events')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CalendarEventsController {
  constructor(private readonly calendarEventsService: CalendarEventsService) {}

  @Post()
  @Roles(UserRole.CLUB)
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateCalendarEventDto,
  ) {
    const events = await this.calendarEventsService.create(user.sub, dto);
    return { items: events.map(toCalendarEventView) };
  }

  @Get()
  @Roles(UserRole.CLUB)
  async list(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListCalendarEventsDto,
  ) {
    const events = await this.calendarEventsService.listForClub(
      user.sub,
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
  @Roles(UserRole.CLUB)
  async rosterPool(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const groups = await this.calendarEventsService.rosterPool(user.sub, id);
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
  @Roles(UserRole.CLUB)
  async updateRoster(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateRosterDto,
  ) {
    const event = await this.calendarEventsService.updateRoster(
      user.sub,
      id,
      dto,
    );
    return toCalendarEventView(event);
  }

  @Get(':id')
  @Roles(UserRole.CLUB, UserRole.PLAYER)
  async findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const event = await this.calendarEventsService.findByIdForParty(
      user.sub,
      id,
      user.role === UserRole.CLUB ? 'CLUB' : 'PLAYER',
    );
    return toCalendarEventView(event);
  }

  @Patch(':id/stats')
  @Roles(UserRole.CLUB)
  async updateStats(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateStatsDto,
  ) {
    const event = await this.calendarEventsService.updateStats(
      user.sub,
      id,
      dto,
    );
    return toCalendarEventView(event);
  }

  @Delete(':id')
  @Roles(UserRole.CLUB)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.calendarEventsService.remove(user.sub, id);
  }
}
