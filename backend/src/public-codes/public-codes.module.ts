import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PublicCodesService } from './public-codes.service';
import { Counter, CounterSchema } from './schemas/counter.schema';

// Shared by PlayersModule and ClubsModule — the two profile types allocate
// their public codes (PLY-…/CLB-…) from the same counter collection, so the
// allocator lives in one place rather than being duplicated per profile.
@Module({
  imports: [
    MongooseModule.forFeature([{ name: Counter.name, schema: CounterSchema }]),
  ],
  providers: [PublicCodesService],
  exports: [PublicCodesService],
})
export class PublicCodesModule {}
