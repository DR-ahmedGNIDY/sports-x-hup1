import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { UserRole } from '../../users/schemas/user.schema';
import { toAdminShippingZoneView, toShippingZoneView } from '../store.mapper';
import {
  CreateShippingCityDto,
  UpdateShippingCityDto,
} from './dto/upsert-shipping-city.dto';
import { UpsertShippingZoneDto } from './dto/upsert-shipping-zone.dto';
import { ShippingService } from './shipping.service';

// Public: the checkout has to show delivery cost per governorate before the
// customer commits to anything, so this is readable without a session.
@Controller('store/shipping-zones')
export class ShippingController {
  constructor(private readonly shipping: ShippingService) {}

  @Get()
  async listActive() {
    const zones = await this.shipping.listActive();
    return { items: zones.map(toShippingZoneView) };
  }
}

@Controller('admin/store/shipping-zones')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminShippingController {
  constructor(private readonly shipping: ShippingService) {}

  @Get()
  async listAll() {
    const zones = await this.shipping.listAll();
    return { items: zones.map(toAdminShippingZoneView) };
  }

  @Post()
  async create(@Body() dto: UpsertShippingZoneDto) {
    return toAdminShippingZoneView(await this.shipping.create(dto));
  }

  // No DELETE: a zone is deactivated through `isActive` on this same body.
  // Removing the row would strand every order that shipped to it.
  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpsertShippingZoneDto) {
    return toAdminShippingZoneView(await this.shipping.update(id, dto));
  }

  @Post(':id/cities')
  async addCity(
    @Param('id') id: string,
    @Body() dto: CreateShippingCityDto,
  ) {
    return toAdminShippingZoneView(await this.shipping.addCity(id, dto));
  }

  // No DELETE here either, for the same reason as the zone itself.
  @Patch(':id/cities/:cityCode')
  async updateCity(
    @Param('id') id: string,
    @Param('cityCode') cityCode: string,
    @Body() dto: UpdateShippingCityDto,
  ) {
    return toAdminShippingZoneView(
      await this.shipping.updateCity(id, cityCode, dto),
    );
  }
}
