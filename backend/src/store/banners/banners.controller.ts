import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { imageUploadOptions } from '../../common/upload.config';
import { UserRole } from '../../users/schemas/user.schema';
import { toAdminBannerView, toBannerView } from '../store.mapper';
import { isBannerSlot } from './banner-slot';
import { BannersService } from './banners.service';
import { UpsertBannerDto } from './dto/upsert-banner.dto';

/// The storefront hero. Public and unauthenticated — it is the first thing
/// on the shop's front page.
@Controller('store/banners')
export class BannersController {
  constructor(private readonly banners: BannersService) {}

  @Get()
  async listPublished() {
    const banners = await this.banners.listPublished();
    return { items: banners.map(toBannerView) };
  }
}

@Controller('admin/store/banners')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminBannersController {
  constructor(private readonly banners: BannersService) {}

  // Includes the unfinished ones the public endpoint withholds, so the
  // merchant can see why a banner is not showing.
  @Get()
  async listAll() {
    const banners = await this.banners.listAll();
    return { items: banners.map(toAdminBannerView) };
  }

  @Post()
  async create(@Body() dto: UpsertBannerDto) {
    return toAdminBannerView(await this.banners.create(dto));
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpsertBannerDto) {
    return toAdminBannerView(await this.banners.update(id, dto));
  }

  // The slot is a path segment rather than a body field because the request
  // is multipart: mixing a discriminator into the form data would mean
  // parsing the upload before knowing what to do with it.
  @Post(':id/image/:slot')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async setImage(
    @Param('id') id: string,
    @Param('slot') slot: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!isBannerSlot(slot)) {
      throw new BadRequestException('slot must be "desktop" or "mobile".');
    }
    return toAdminBannerView(await this.banners.setImage(id, slot, file));
  }

  @Delete(':id/image/:slot')
  async removeImage(@Param('id') id: string, @Param('slot') slot: string) {
    if (!isBannerSlot(slot)) {
      throw new BadRequestException('slot must be "desktop" or "mobile".');
    }
    return toAdminBannerView(await this.banners.removeImage(id, slot));
  }

  // Deactivates — see the service.
  @Delete(':id')
  async deactivate(@Param('id') id: string) {
    return toAdminBannerView(await this.banners.deactivate(id));
  }
}
