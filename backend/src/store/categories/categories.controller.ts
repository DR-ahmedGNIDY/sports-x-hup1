import {
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
import { imageUploadOptions } from '../../common/upload.config';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { UserRole } from '../../users/schemas/user.schema';
import { toAdminCategoryView, toCategoryView } from '../store.mapper';
import { StoreCategoriesService } from './categories.service';
import { UpsertCategoryDto } from './dto/upsert-category.dto';

// Public storefront navigation. Unauthenticated by design — the catalogue
// is the shop window, and requiring a session to see it would be the same
// mistake as locking the front door of the shop.
@Controller('store/categories')
export class StoreCategoriesController {
  constructor(private readonly categories: StoreCategoriesService) {}

  @Get()
  async listActive() {
    const categories = await this.categories.listActive();
    return { items: categories.map(toCategoryView) };
  }
}

// Merchant-facing. Mounted on its own path rather than guarded per-handler
// so that no route on this controller can ever be added without the guard.
@Controller('admin/store/categories')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminStoreCategoriesController {
  constructor(private readonly categories: StoreCategoriesService) {}

  @Get()
  async listAll() {
    const categories = await this.categories.listAll();
    return { items: categories.map(toAdminCategoryView) };
  }

  @Post()
  async create(@Body() dto: UpsertCategoryDto) {
    return toAdminCategoryView(await this.categories.create(dto));
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpsertCategoryDto) {
    return toAdminCategoryView(await this.categories.update(id, dto));
  }

  // DELETE, but a deactivation — see the service. Products already point
  // here and orders already reference those products, so a real delete
  // would leave both dangling. The verb matches the merchant's intent
  // ("remove this from my shop"); the storage decision is ours.
  @Delete(':id')
  async deactivate(@Param('id') id: string) {
    return toAdminCategoryView(await this.categories.deactivate(id));
  }

  // Replaces the category's single image — see the service.
  @Post(':id/image')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async setImage(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return toAdminCategoryView(await this.categories.setImage(id, file));
  }
}
