import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { toNotificationView } from './notifications.mapper';
import { NotificationsService } from './notifications.service';

// Every route here is the caller's own mailbox. No @Roles: a notification
// belongs to an account, not to a kind of account, and admins have one too
// even though nothing currently writes to it.
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

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

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  async read(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return toNotificationView(await this.notifications.markRead(user.sub, id));
  }
}
