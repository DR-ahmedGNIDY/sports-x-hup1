import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { StoreOrder, StoreOrderSchema } from '../schemas/order.schema';
import { StoreProduct, StoreProductSchema } from '../schemas/product.schema';
import { AdminStoreOverviewController } from './overview.controller';
import { StoreOverviewService } from './overview.service';

// Reads across orders and products, so it registers both models rather than
// reaching into the other modules' services — every query here is a count or
// an aggregation those services have no reason to expose.
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreOrder.name, schema: StoreOrderSchema },
      { name: StoreProduct.name, schema: StoreProductSchema },
    ]),
  ],
  controllers: [AdminStoreOverviewController],
  providers: [StoreOverviewService],
})
export class StoreOverviewModule {}
