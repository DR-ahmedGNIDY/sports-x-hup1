import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseEnumPipe,
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
import {
  CreateSubscriptionDto,
  UpdateSubscriptionDto,
} from './dto/upsert-subscription.dto';
import {
  toSubscriptionView,
  toSubscriptionViewOrNull,
} from './player-subscriptions.mapper';
import { PlayerSubscriptionsService } from './player-subscriptions.service';
import { SubscriptionStatus } from './subscription-dates';

// The club account only. Amounts and payments are the club's money, so
// coaches on its staff — who reach the roster through X-Club-Id — are not
// let in here.
@Controller('club-subscriptions')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CLUB)
export class ClubSubscriptionsController {
  constructor(private readonly subscriptions: PlayerSubscriptionsService) {}

  @Get()
  async overview(
    @CurrentUser() user: JwtPayload,
    @Query('status', new ParseEnumPipe(SubscriptionStatus, { optional: true }))
    status?: SubscriptionStatus,
  ) {
    const overview = await this.subscriptions.overviewForClub(user.sub, status);
    return {
      ...overview,
      items: overview.items.map((row) => ({
        ...row,
        current: toSubscriptionViewOrNull(row.current),
      })),
    };
  }

  @Get('players/:playerUserId')
  async player(
    @CurrentUser() user: JwtPayload,
    @Param('playerUserId') playerUserId: string,
  ) {
    const detail = await this.subscriptions.playerDetailForClub(
      user.sub,
      playerUserId,
    );
    return { ...detail, history: detail.history.map(toSubscriptionView) };
  }

  @Post('players/:playerUserId/remind')
  @HttpCode(204)
  async remind(
    @CurrentUser() user: JwtPayload,
    @Param('playerUserId') playerUserId: string,
  ) {
    await this.subscriptions.remind(user.sub, playerUserId);
  }

  @Post()
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateSubscriptionDto,
  ) {
    return toSubscriptionView(await this.subscriptions.create(user.sub, dto));
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateSubscriptionDto,
  ) {
    return toSubscriptionView(
      await this.subscriptions.update(user.sub, id, dto),
    );
  }

  @Post(':id/renew')
  async renew(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return toSubscriptionView(await this.subscriptions.renew(user.sub, id));
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.subscriptions.remove(user.sub, id);
  }
}

@Controller('my-subscription')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.PLAYER)
export class MySubscriptionController {
  constructor(private readonly subscriptions: PlayerSubscriptionsService) {}

  @Get()
  async mine(@CurrentUser() user: JwtPayload) {
    const mine = await this.subscriptions.mine(user.sub);
    return { ...mine, current: toSubscriptionViewOrNull(mine.current) };
  }
}
