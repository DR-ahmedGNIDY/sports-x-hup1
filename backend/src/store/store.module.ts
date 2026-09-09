import { Module } from '@nestjs/common';
import { BannersModule } from './banners/banners.module';
import { StoreCategoriesModule } from './categories/categories.module';
import { CouponsModule } from './coupons/coupons.module';
import { OrdersModule } from './orders/orders.module';
import { StoreOverviewModule } from './overview/overview.module';
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
    StoreOverviewModule,
    CouponsModule,
    BannersModule,
  ],
})
export class StoreModule {}
