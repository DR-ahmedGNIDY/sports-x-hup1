import { Module } from '@nestjs/common';
import { StoreCategoriesModule } from './categories/categories.module';
import { OrdersModule } from './orders/orders.module';
import { StoreProductsModule } from './products/products.module';
import { ShippingModule } from './shipping/shipping.module';

// The storefront's aggregate root. AppModule imports this one module rather
// than each store sub-module, so the next piece — coupons, a payment
// gateway — is added here without touching the application root again.
@Module({
  imports: [
    StoreCategoriesModule,
    StoreProductsModule,
    ShippingModule,
    OrdersModule,
  ],
})
export class StoreModule {}
