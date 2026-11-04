import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
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
import { ClubActor } from '../club-access/club-access.service';
import {
  ClubActorGuard,
  ClubActorParam,
  ClubPermission,
} from '../club-access/club-actor.guard';
import { CoachPermission } from '../club-access/coach-permission.enum';
import { UserRole } from '../users/schemas/user.schema';
import {
  ParticipantDto,
  ParticipantOrderDto,
  RecordResultDto,
  UpdateFixtureDto,
  UpsertTournamentDto,
} from './dto/tournament.dto';
import {
  toDetailView,
  toFixtureView,
  toParticipantView,
  toTournamentView,
} from './tournaments.mapper';
import { TournamentsService } from './tournaments.service';

// The club account, and any coach it granted MANAGE_TOURNAMENTS (sent with
// X-Club-Id, like every other club screen a coach uses).
@Controller('club-tournaments')
@UseGuards(JwtAuthGuard, RolesGuard, ClubActorGuard)
@Roles(UserRole.CLUB, UserRole.COACH)
@ClubPermission(CoachPermission.MANAGE_TOURNAMENTS)
export class ClubTournamentsController {
  constructor(private readonly tournaments: TournamentsService) {}

  @Get()
  async list(@ClubActorParam() actor: ClubActor) {
    const rows = await this.tournaments.listForClub(actor.clubUserId);
    return rows.map((row) => ({
      ...toTournamentView(row.tournament),
      participantsCount: row.participantsCount,
    }));
  }

  @Post()
  async create(
    @ClubActorParam() actor: ClubActor,
    @Body() dto: UpsertTournamentDto,
  ) {
    return toTournamentView(
      await this.tournaments.create(
        actor.clubUserId,
        actor.actorUserId,
        dto,
      ),
    );
  }

  @Get(':id')
  async detail(@ClubActorParam() actor: ClubActor, @Param('id') id: string) {
    return toDetailView(
      await this.tournaments.detailForClub(actor.clubUserId, id),
    );
  }

  @Patch(':id')
  async update(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Body() dto: UpsertTournamentDto,
  ) {
    return toTournamentView(
      await this.tournaments.update(actor.clubUserId, id, dto),
    );
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@ClubActorParam() actor: ClubActor, @Param('id') id: string) {
    await this.tournaments.remove(actor.clubUserId, id);
  }

  // ------------------------------------------------------------ participants

  @Get(':id/eligible-players')
  eligiblePlayers(@ClubActorParam() actor: ClubActor, @Param('id') id: string) {
    return this.tournaments.eligiblePlayers(actor.clubUserId, id);
  }

  @Post(':id/participants')
  async addParticipant(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Body() dto: ParticipantDto,
  ) {
    return toParticipantView(
      await this.tournaments.addParticipant(actor.clubUserId, id, dto),
    );
  }

  // Declared before ':participantId' so "order" is never read as an id.
  @Patch(':id/participants/order')
  @HttpCode(204)
  async orderParticipants(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Body() dto: ParticipantOrderDto,
  ) {
    await this.tournaments.orderParticipants(actor.clubUserId, id, dto.order);
  }

  @Patch(':id/participants/:participantId')
  async updateParticipant(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ParticipantDto,
  ) {
    return toParticipantView(
      await this.tournaments.updateParticipant(
        actor.clubUserId,
        id,
        participantId,
        dto,
      ),
    );
  }

  @Delete(':id/participants/:participantId')
  @HttpCode(204)
  async removeParticipant(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Param('participantId') participantId: string,
  ) {
    await this.tournaments.removeParticipant(
      actor.clubUserId,
      id,
      participantId,
    );
  }

  // ---------------------------------------------------------------- schedule

  @Post(':id/generate')
  async generate(@ClubActorParam() actor: ClubActor, @Param('id') id: string) {
    return toDetailView(await this.tournaments.generate(actor.clubUserId, id));
  }

  @Delete(':id/fixtures')
  @HttpCode(204)
  async resetFixtures(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
  ) {
    await this.tournaments.resetFixtures(actor.clubUserId, id);
  }

  @Patch(':id/fixtures/:fixtureId')
  async updateFixture(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Param('fixtureId') fixtureId: string,
    @Body() dto: UpdateFixtureDto,
  ) {
    return toFixtureView(
      await this.tournaments.updateFixture(
        actor.clubUserId,
        id,
        fixtureId,
        dto,
      ),
    );
  }

  @Post(':id/fixtures/:fixtureId/result')
  async recordResult(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Param('fixtureId') fixtureId: string,
    @Body() dto: RecordResultDto,
  ) {
    return toDetailView(
      await this.tournaments.recordResult(
        actor.clubUserId,
        id,
        fixtureId,
        dto,
      ),
    );
  }

  @Delete(':id/fixtures/:fixtureId/result')
  async clearResult(
    @ClubActorParam() actor: ClubActor,
    @Param('id') id: string,
    @Param('fixtureId') fixtureId: string,
  ) {
    return toDetailView(
      await this.tournaments.clearResult(actor.clubUserId, id, fixtureId),
    );
  }
}

/** The players' read-only portal. */
@Controller('my-tournaments')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.PLAYER)
export class MyTournamentsController {
  constructor(private readonly tournaments: TournamentsService) {}

  @Get()
  async list(@CurrentUser() user: JwtPayload) {
    const rows = await this.tournaments.listForPlayer(user.sub);
    return rows.map((row) => ({
      ...toTournamentView(row.tournament),
      participantsCount: row.participantsCount,
      isParticipant: row.isParticipant,
    }));
  }

  @Get(':id')
  async detail(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return toDetailView(await this.tournaments.detailForPlayer(user.sub, id));
  }
}
