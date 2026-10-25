import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ShippingCity,
  ShippingZone,
  ShippingZoneDocument,
} from '../schemas/shipping-zone.schema';
import {
  CreateShippingCityDto,
  UpdateShippingCityDto,
} from './dto/upsert-shipping-city.dto';
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

  // Resolved here rather than by the checkout trusting a fee it already has:
  // a chosen city can be stale or disabled by the time the order is placed.
  // No `cityCode` and no cities priced yet on this governorate falls back to
  // the governorate's own fee, so pricing can roll out city by city.
  resolveFee(
    zone: ShippingZoneDocument,
    cityCode?: string,
  ): { feeMinor: number; city?: ShippingCity } {
    const activeCities = (zone.cities ?? []).filter((city) => city.isActive);

    if (cityCode) {
      const city = activeCities.find(
        (candidate) => candidate.code === cityCode.toLowerCase(),
      );
      if (!city) {
        throw new NotFoundException('We do not deliver to that city.');
      }
      return { feeMinor: city.feeMinor, city };
    }

    if (activeCities.length > 0) {
      throw new BadRequestException('Choose a city for that governorate.');
    }

    return { feeMinor: zone.feeMinor };
  }

  async addCity(
    zoneId: string,
    dto: CreateShippingCityDto,
  ): Promise<ShippingZoneDocument> {
    const zone = await this.zoneModel.findById(zoneId);
    if (!zone) throw new NotFoundException('Shipping zone not found.');

    const code = dto.code.toLowerCase();
    if (zone.cities.some((city) => city.code === code)) {
      throw new ConflictException(
        'A city with that code already exists in this governorate.',
      );
    }

    zone.cities.push({
      name: { en: dto.name.en, ar: dto.name.ar },
      code,
      feeMinor: dto.feeMinor,
      isActive: dto.isActive ?? true,
      sortOrder: dto.sortOrder ?? 0,
    } as ShippingCity);
    return (await zone.save()) as ShippingZoneDocument;
  }

  async updateCity(
    zoneId: string,
    cityCode: string,
    dto: UpdateShippingCityDto,
  ): Promise<ShippingZoneDocument> {
    const zone = await this.zoneModel.findById(zoneId);
    if (!zone) throw new NotFoundException('Shipping zone not found.');

    const city = zone.cities.find(
      (candidate) => candidate.code === cityCode.toLowerCase(),
    );
    if (!city) {
      throw new NotFoundException('City not found in this governorate.');
    }

    city.name = { en: dto.name.en, ar: dto.name.ar };
    city.feeMinor = dto.feeMinor;
    if (dto.isActive !== undefined) city.isActive = dto.isActive;
    if (dto.sortOrder !== undefined) city.sortOrder = dto.sortOrder;
    return (await zone.save()) as ShippingZoneDocument;
  }
}
