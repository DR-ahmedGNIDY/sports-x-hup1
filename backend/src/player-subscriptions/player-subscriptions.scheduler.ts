import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PlayerSubscriptionsService } from './player-subscriptions.service';
import { ACADEMY_TIME_ZONE } from './subscription-dates';

/**
 * Once a day, in the morning where the academies are. The API runs as a
 * single pm2 process, so there is one scheduler; the service's own claims
 * keep a second one (a restart mid-run) from announcing anything twice.
 */
@Injectable()
export class PlayerSubscriptionsScheduler {
  constructor(private readonly subscriptions: PlayerSubscriptionsService) {}

  @Cron('0 9 * * *', {
    name: 'subscription-expiries',
    timeZone: ACADEMY_TIME_ZONE,
  })
  async announceExpiries(): Promise<void> {
    await this.subscriptions.announceExpiries();
  }
}
