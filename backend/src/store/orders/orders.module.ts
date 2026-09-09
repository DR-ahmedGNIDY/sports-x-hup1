import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PublicCodesModule } from '../../public-codes/public-codes.module';
import { StoreOrder, StoreOrderSchema } from '../schemas/order.schema';
import { StoreProduct, StoreProductSchema } from '../schemas/product.schema';
import { CouponsModule } from '../coupons/coupons.module';
import { ShippingModule } from '../shipping/shipping.module';
import { AdminOrdersController, OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreOrder.name, schema: StoreOrderSchema },
      // Registered here as well as in StoreProductsModule: checkout writes
      // stock directly through conditional atomic updates, which is a
      // different operation from anything the products service exposes.
      { name: StoreProduct.name, schema: StoreProductSchema },
    ]),
    ShippingModule,
    PublicCodesModule,
    CouponsModule,
  ],
  controllers: [OrdersController, AdminOrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
