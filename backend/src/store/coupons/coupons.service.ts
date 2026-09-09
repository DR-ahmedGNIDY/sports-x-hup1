import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Coupon, CouponDocument, CouponType } from '../schemas/coupon.schema';
import { UpsertCouponDto } from './dto/upsert-coupon.dto';

/// What a coupon is worth against one basket, and the code as stored — the
/// order records the canonical upper-cased form, not what the customer typed.
export interface CouponDiscount {
  code: string;
  discountMinor: number;
}

@Injectable()
export class CouponsService {
  constructor(
    @InjectModel(Coupon.name)
    private readonly couponModel: Model<Coupon>,
  ) {}

  /// Prices a code against a subtotal without consuming it — this is what
  /// the cart calls to show "−50.00 EGP" before the customer commits.
  ///
  /// Every rejection is a distinct message on purpose: "expired" and "your
  /// basket is too small" are different problems, and a single "invalid
  /// code" makes the second one unsolvable for the customer.
  async priceFor(
    rawCode: string,
    subtotalMinor: number,
  ): Promise<CouponDiscount> {
    const coupon = await this.findUsableOrThrow(rawCode);

    if (subtotalMinor < coupon.minSubtotalMinor) {
      throw new BadRequestException(
        `This code needs a basket of at least ${formatMinor(coupon.minSubtotalMinor)}.`,
      );
    }

    return {
      code: coupon.code,
      discountMinor: discountFor(coupon, subtotalMinor),
    };
  }

  /// Prices the code *and* takes one of its redemptions, atomically.
  ///
  /// The `$inc` is guarded by the same conditions that made the code usable,
  /// so two checkouts racing for the last redemption of a limited code
  /// cannot both win — the loser's update matches nothing and it is told the
  /// code is used up, rather than both orders getting the discount.
  async claim(rawCode: string, subtotalMinor: number): Promise<CouponDiscount> {
    const priced = await this.priceFor(rawCode, subtotalMinor);

    const claimed = await this.couponModel.findOneAndUpdate(
      { code: priced.code, ...usableFilter() },
      { $inc: { redemptions: 1 } },
      { new: true },
    );
    if (!claimed) {
      throw new ConflictException('This code is no longer available.');
    }

    return priced;
  }

  /// Gives a redemption back when an order that used the code is cancelled.
  /// Floored at zero so a double release cannot drive the counter negative
  /// and silently hand out an extra use.
  async release(code: string): Promise<void> {
    await this.couponModel.updateOne(
      { code: code.trim().toUpperCase(), redemptions: { $gt: 0 } },
      { $inc: { redemptions: -1 } },
    );
  }

  private async findUsableOrThrow(rawCode: string): Promise<CouponDocument> {
    const code = rawCode.trim().toUpperCase();
    const coupon = await this.couponModel.findOne({ code });
    if (!coupon) throw new NotFoundException('That code does not exist.');

    const now = new Date();
    if (!coupon.isActive) {
      throw new BadRequestException('This code is no longer active.');
    }
    if (coupon.startsAt && coupon.startsAt > now) {
      throw new BadRequestException('This code is not available yet.');
    }
    if (coupon.endsAt && coupon.endsAt < now) {
      throw new BadRequestException('This code has expired.');
    }
    if (
      coupon.maxRedemptions !== undefined &&
      coupon.redemptions >= coupon.maxRedemptions
    ) {
      throw new BadRequestException('This code has been fully used.');
    }
    return coupon;
  }

  // ------------------------------------------------------------------ admin

  async listAll(): Promise<CouponDocument[]> {
    return this.couponModel.find().sort({ createdAt: -1 }).exec();
  }

  async create(dto: UpsertCouponDto): Promise<CouponDocument> {
    this.assertCoherent(dto);
    const code = dto.code.trim().toUpperCase();
    if (await this.couponModel.exists({ code })) {
      throw new ConflictException('A coupon with that code already exists.');
    }
    return this.couponModel.create({
      code,
      type: dto.type,
      value: dto.value,
      minSubtotalMinor: dto.minSubtotalMinor ?? 0,
      maxRedemptions: dto.maxRedemptions,
      startsAt: dto.startsAt,
      endsAt: dto.endsAt,
      isActive: dto.isActive ?? true,
    });
  }

  async update(id: string, dto: UpsertCouponDto): Promise<CouponDocument> {
    this.assertCoherent(dto);
    const coupon = await this.couponModel.findById(id);
    if (!coupon) throw new NotFoundException('Coupon not found.');

    // The code is what customers already hold; changing it would silently
    // invalidate every post and receipt carrying it.
    if (dto.code.trim().toUpperCase() !== coupon.code) {
      throw new ConflictException(
        'A coupon code cannot be changed — deactivate this one and create another.',
      );
    }

    coupon.type = dto.type;
    coupon.value = dto.value;
    coupon.minSubtotalMinor = dto.minSubtotalMinor ?? 0;
    coupon.maxRedemptions = dto.maxRedemptions;
    coupon.startsAt = dto.startsAt;
    coupon.endsAt = dto.endsAt;
    if (dto.isActive !== undefined) coupon.isActive = dto.isActive;
    return coupon.save();
  }

  private assertCoherent(dto: UpsertCouponDto): void {
    if (dto.type === CouponType.PERCENT && dto.value > 100) {
      throw new BadRequestException('A percentage discount cannot exceed 100.');
    }
    if (dto.startsAt && dto.endsAt && dto.startsAt >= dto.endsAt) {
      throw new BadRequestException('The end date must be after the start.');
    }
  }
}

/// The conditions that make a coupon usable right now, as a query — shared
/// by the read in [CouponsService.priceFor] and the guarded write in
/// [CouponsService.claim] so the two can never drift apart.
function usableFilter(): Record<string, unknown> {
  const now = new Date();
  return {
    isActive: true,
    $and: [
      { $or: [{ startsAt: { $exists: false } }, { startsAt: { $lte: now } }] },
      { $or: [{ endsAt: { $exists: false } }, { endsAt: { $gte: now } }] },
      {
        $or: [
          { maxRedemptions: { $exists: false } },
          { $expr: { $lt: ['$redemptions', '$maxRedemptions'] } },
        ],
      },
    ],
  };
}

/// Never more than the basket: a 200 EGP code against a 150 EGP basket is a
/// 150 EGP discount, not a 50 EGP refund.
export function discountFor(
  coupon: Pick<Coupon, 'type' | 'value'>,
  subtotalMinor: number,
): number {
  const raw =
    coupon.type === CouponType.PERCENT
      ? Math.round((subtotalMinor * coupon.value) / 100)
      : coupon.value;
  return Math.min(raw, subtotalMinor);
}

function formatMinor(minor: number): string {
  return `${(minor / 100).toFixed(2)} EGP`;
}
