import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
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
import {
  toAdminProductView,
  toProductCardView,
  toProductDetailView,
} from '../store.mapper';
import { ListProductsDto } from './dto/list-products.dto';
import { UpsertProductDto } from './dto/upsert-product.dto';
import { StoreProductsService } from './products.service';

@Controller('store/products')
export class StoreProductsController {
  constructor(private readonly products: StoreProductsService) {}

  // GET /store/products — the listing, the search results and the category
  // page are all this one endpoint with different query parameters.
  @Get()
  async list(@Query() query: ListProductsDto) {
    const result = await this.products.list(query);
    return { ...result, items: result.items.map(toProductCardView) };
  }

  // Addressed by slug, not id: the storefront URL is the shareable one, and
  // resolving it directly saves the front end a lookup. Declared after the
  // bare GET above so `/store/products` can never be read as a slug.
  @Get(':slug')
  async findBySlug(@Param('slug') slug: string) {
    return toProductDetailView(await this.products.findBySlugOrThrow(slug));
  }
}

@Controller('admin/store/products')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminStoreProductsController {
  constructor(private readonly products: StoreProductsService) {}

  // Same query builder as the storefront, with the inactive products the
  // merchant still has to be able to find and re-list.
  @Get()
  async list(@Query() query: ListProductsDto) {
    const result = await this.products.list(query, true);
    return { ...result, items: result.items.map(toAdminProductView) };
  }

  // By id here, not slug: the admin table is editing a row it already holds
  // the id of, and an inactive product has no storefront URL to address.
  @Get(':id')
  async findById(@Param('id') id: string) {
    return toAdminProductView(await this.products.findByIdOrThrow(id));
  }

  @Post()
  async create(@Body() dto: UpsertProductDto) {
    return toAdminProductView(await this.products.create(dto));
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpsertProductDto) {
    return toAdminProductView(await this.products.update(id, dto));
  }

  // Unlists rather than deletes — see the service.
  @Delete(':id')
  async deactivate(@Param('id') id: string) {
    return toAdminProductView(await this.products.deactivate(id));
  }

  // Multipart, and separate from the JSON body above: an image is not a
  // field of the product, it is a file that has to reach Cloudinary before
  // the product can reference it at all.
  @Post(':id/images')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async addImage(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return toAdminProductView(await this.products.addImage(id, file));
  }

  // The Cloudinary publicId, not an index: an index would address a
  // different image if the gallery changed between the merchant loading
  // the page and clicking delete.
  @Delete(':id/images/:publicId')
  async removeImage(
    @Param('id') id: string,
    @Param('publicId') publicId: string,
  ) {
    return toAdminProductView(
      await this.products.removeImage(id, decodeURIComponent(publicId)),
    );
  }
}
