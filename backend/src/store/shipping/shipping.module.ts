import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ShippingZone,
  ShippingZoneSchema,
} from '../schemas/shipping-zone.schema';
import {
  AdminShippingController,
  ShippingController,
} from './shipping.controller';
import { ShippingService } from './shipping.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ShippingZone.name, schema: ShippingZoneSchema },
    ]),
  ],
  controllers: [ShippingController, AdminShippingController],
  providers: [ShippingService],
  // Orders prices the delivery fee through this service at checkout.
  exports: [ShippingService],
})
export class ShippingModule {}
