import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CloudinaryModule } from '../../cloudinary/cloudinary.module';
import { StoreImagesService } from '../store-images.service';
import { StoreProduct, StoreProductSchema } from '../schemas/product.schema';
import { StoreCategoriesModule } from '../categories/categories.module';
import {
  AdminStoreProductsController,
  StoreProductsController,
} from './products.controller';
import { StoreProductsService } from './products.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreProduct.name, schema: StoreProductSchema },
    ]),
    StoreCategoriesModule,
    CloudinaryModule,
  ],
  controllers: [StoreProductsController, AdminStoreProductsController],
  providers: [StoreProductsService, StoreImagesService],
  exports: [StoreProductsService],
})
export class StoreProductsModule {}
