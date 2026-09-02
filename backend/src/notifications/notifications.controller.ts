import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import {
  CreatePushSubscriptionDto,
  DeletePushSubscriptionDto,
} from './dto/push-subscription.dto';
import { toNotificationView } from './notifications.mapper';
import { NotificationsService } from './notifications.service';
import { PushService } from './push.service';

// Every route here is the caller's own mailbox. No @Roles: a notification
// belongs to an account, not to a kind of account, and admins have one too
// even though nothing currently writes to it.
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly notifications: NotificationsService,
    private readonly push: PushService,
    private readonly config: ConfigService,
  ) {}

  @Get()
  async list(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListNotificationsDto,
  ) {
    const result = await this.notifications.list(user.sub, {
      page: dto.page,
      unreadOnly: dto.unreadOnly,
    });
    return {
      items: result.items.map(toNotificationView),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  // Fixed path, registered before the ':id' route below so "summary" is
  // never matched as a notification id.
  @Get('summary')
  async summary(@CurrentUser() user: JwtPayload) {
    return { unread: await this.notifications.unreadCount(user.sub) };
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  async readAll(@CurrentUser() user: JwtPayload) {
    return { marked: await this.notifications.markAllRead(user.sub) };
  }

  // ------------------------------------------------------------ web push
  //
  // Fixed paths, all registered before the ':id' route below so none of them
  // is ever matched as a notification id.

  /// `null` when the server has no VAPID keys configured. The client reads
  /// this before asking for permission: prompting for a capability the
  /// backend cannot deliver would spend the one prompt a browser gives you.
  @Get('push/public-key')
  publicKey() {
    return { publicKey: this.push.publicKey(this.config) };
  }

  @Post('push/subscribe')
  @HttpCode(HttpStatus.OK)
  async subscribe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePushSubscriptionDto,
    @Headers('user-agent') userAgent?: string,
  ) {
    await this.push.subscribe({
      userId: user.sub,
      endpoint: dto.endpoint,
      p256dh: dto.keys.p256dh,
      auth: dto.keys.auth,
      userAgent,
    });
    return { subscribed: true };
  }

  @Post('push/unsubscribe')
  @HttpCode(HttpStatus.OK)
  async unsubscribe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: DeletePushSubscriptionDto,
  ) {
    // Scoped to the caller: an endpoint is guessable in principle, and
    // nobody should be able to silence someone else's phone.
    await this.push.unsubscribe(user.sub, dto.endpoint);
    return { subscribed: false };
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  async read(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return toNotificationView(await this.notifications.markRead(user.sub, id));
  }
}
