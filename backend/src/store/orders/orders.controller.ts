import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  JwtPayload,
} from '../../auth/decorators/current-user.decorator';
import { OptionalCurrentUser } from '../../auth/decorators/optional-current-user.decorator';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../../auth/guards/optional-jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { UserRole } from '../../users/schemas/user.schema';
import { toOrderView } from '../store.mapper';
import { CreateOrderDto } from './dto/create-order.dto';
import { ListOrdersDto } from './dto/list-orders.dto';
import { TrackOrderDto } from './dto/track-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrdersService } from './orders.service';

@Controller('store/orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  // Checkout. Behind the optional guard rather than the normal one so a
  // guest can buy; a request that does carry a valid session has its order
  // attached to that account and gains an order history.
  @Post()
  @UseGuards(OptionalJwtAuthGuard)
  // Placing an order writes stock and allocates an order number, so it is
  // rate-limited well below the API-wide default — the cost of a scripted
  // flood here is real inventory being held.
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async create(
    @Body() dto: CreateOrderDto,
    @OptionalCurrentUser() user?: JwtPayload,
  ) {
    return toOrderView(await this.orders.create(dto, user?.sub));
  }

  // Guest retrieval: order number plus the email it was placed with. A POST
  // rather than a GET because the email is a credential here, and a GET
  // would put it in the query string, where it lands in access logs and
  // browser history.
  @Post('track')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async track(@Body() dto: TrackOrderDto) {
    return toOrderView(
      await this.orders.trackForGuest(dto.orderNumber, dto.email),
    );
  }

  // Declared before `:id` so the literal path is never read as an id.
  @Get('mine')
  @UseGuards(JwtAuthGuard)
  async mine(@CurrentUser() user: JwtPayload, @Query() query: ListOrdersDto) {
    const result = await this.orders.listForUser(user.sub, query);
    return { ...result, items: result.items.map(toOrderView) };
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async findMine(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return toOrderView(await this.orders.findOwnedByUserOrThrow(id, user.sub));
  }
}

@Controller('admin/store/orders')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminOrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  async list(@Query() query: ListOrdersDto) {
    const result = await this.orders.listForAdmin(query);
    return { ...result, items: result.items.map(toOrderView) };
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return toOrderView(await this.orders.findByIdOrThrow(id));
  }

  // The only mutation the merchant has. Which moves are legal is decided by
  // the service, not by the caller — see ALLOWED_STATUS_TRANSITIONS.
  @Patch(':id/status')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return toOrderView(await this.orders.updateStatus(id, dto.status));
  }
}
