import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../../cloudinary/cloudinary.module';
import { StoreImagesService } from '../store-images.service';
import { StoreCategory, StoreCategorySchema } from '../schemas/category.schema';
import {
  AdminStoreCategoriesController,
  StoreCategoriesController,
} from './categories.controller';
import { StoreCategoriesService } from './categories.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreCategory.name, schema: StoreCategorySchema },
    ]),
    CloudinaryModule,
  ],
  controllers: [StoreCategoriesController, AdminStoreCategoriesController],
  providers: [StoreCategoriesService, StoreImagesService],
  // Products validates its category reference through this service rather
  // than reaching for the model directly.
  exports: [StoreCategoriesService],
})
export class StoreCategoriesModule {}
