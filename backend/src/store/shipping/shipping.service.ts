import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ShippingZone,
  ShippingZoneDocument,
} from '../schemas/shipping-zone.schema';
import { UpsertShippingZoneDto } from './dto/upsert-shipping-zone.dto';

@Injectable()
export class ShippingService {
  constructor(
    @InjectModel(ShippingZone.name)
    private readonly zoneModel: Model<ShippingZone>,
  ) {}

  // Unpaginated: 27 governorates is the whole list, and the checkout needs
  // all of them at once to populate a picker.
  async listActive(): Promise<ShippingZoneDocument[]> {
    return this.zoneModel
      .find({ isActive: true })
      .sort({ sortOrder: 1, code: 1 })
      .exec();
  }

  async listAll(): Promise<ShippingZoneDocument[]> {
    return this.zoneModel.find().sort({ sortOrder: 1, code: 1 }).exec();
  }

  // Checkout resolves the fee through here rather than trusting one sent by
  // the client — the shipping fee is part of the amount collected, so it is
  // priced on the server like everything else on the order.
  async findActiveByCodeOrThrow(code: string): Promise<ShippingZoneDocument> {
    const zone = await this.zoneModel.findOne({
      code: code.toLowerCase(),
      isActive: true,
    });
    if (!zone) {
      throw new NotFoundException('We do not deliver to that governorate.');
    }
    return zone;
  }

  async create(dto: UpsertShippingZoneDto): Promise<ShippingZoneDocument> {
    const taken = await this.zoneModel.exists({ code: dto.code });
    if (taken) {
      throw new ConflictException('A zone with that code already exists.');
    }
    return this.zoneModel.create({
      name: { en: dto.name.en, ar: dto.name.ar },
      code: dto.code,
      feeMinor: dto.feeMinor,
      isActive: dto.isActive ?? true,
      sortOrder: dto.sortOrder ?? 0,
    });
  }

  async update(
    id: string,
    dto: UpsertShippingZoneDto,
  ): Promise<ShippingZoneDocument> {
    const zone = await this.zoneModel.findById(id);
    if (!zone) throw new NotFoundException('Shipping zone not found.');

    // The code is the identity orders were written against; changing it
    // would silently detach every past order from its zone.
    if (dto.code !== zone.code) {
      throw new ConflictException(
        'A zone code cannot be changed once created — deactivate it and add a new one.',
      );
    }

    zone.name = { en: dto.name.en, ar: dto.name.ar };
    zone.feeMinor = dto.feeMinor;
    if (dto.isActive !== undefined) zone.isActive = dto.isActive;
    if (dto.sortOrder !== undefined) zone.sortOrder = dto.sortOrder;
    return zone.save();
  }
}
