import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Coupon, CouponSchema } from '../schemas/coupon.schema';
import {
  AdminCouponsController,
  CouponsController,
} from './coupons.controller';
import { CouponsService } from './coupons.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Coupon.name, schema: CouponSchema }]),
  ],
  controllers: [CouponsController, AdminCouponsController],
  providers: [CouponsService],
  // Checkout claims a redemption through this service, and cancelling an
  // order gives it back.
  exports: [CouponsService],
})
export class CouponsModule {}
