import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { UserRole } from '../../users/schemas/user.schema';
import { toCouponView } from '../store.mapper';
import { CouponsService } from './coupons.service';
import { PreviewCouponDto } from './dto/preview-coupon.dto';
import { UpsertCouponDto } from './dto/upsert-coupon.dto';

@Controller('store/coupons')
export class CouponsController {
  constructor(private readonly coupons: CouponsService) {}

  /// Prices a code for the cart without consuming it.
  ///
  /// Rate-limited well below the API default: this endpoint answers "does
  /// this code exist and what is it worth", which is exactly the shape of
  /// thing worth guessing at in bulk.
  @Post('preview')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async preview(@Body() dto: PreviewCouponDto) {
    return this.coupons.priceFor(dto.code, dto.subtotalMinor);
  }
}

@Controller('admin/store/coupons')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminCouponsController {
  constructor(private readonly coupons: CouponsService) {}

  @Get()
  async listAll() {
    const coupons = await this.coupons.listAll();
    return { items: coupons.map(toCouponView) };
  }

  @Post()
  async create(@Body() dto: UpsertCouponDto) {
    return toCouponView(await this.coupons.create(dto));
  }

  // No DELETE: a coupon is switched off through `isActive` on this body.
  // Removing the row would leave every order that used it referencing a
  // code nothing can explain.
  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpsertCouponDto) {
    return toCouponView(await this.coupons.update(id, dto));
  }
}
