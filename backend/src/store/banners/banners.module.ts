import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../../cloudinary/cloudinary.module';
import { StoreBanner, StoreBannerSchema } from '../schemas/banner.schema';
import { StoreImagesService } from '../store-images.service';
import {
  AdminBannersController,
  BannersController,
} from './banners.controller';
import { BannersService } from './banners.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreBanner.name, schema: StoreBannerSchema },
    ]),
    CloudinaryModule,
  ],
  controllers: [BannersController, AdminBannersController],
  providers: [BannersService, StoreImagesService],
})
export class BannersModule {}
