import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { CouponType } from '../schemas/coupon.schema';
import { CouponsService, discountFor } from './coupons.service';

describe('CouponsService', () => {
  function buildService(coupon: Record<string, unknown> | null) {
    const model = {
      findOne: jest.fn().mockResolvedValue(coupon),
      findOneAndUpdate: jest.fn().mockResolvedValue(coupon),
      findById: jest.fn().mockResolvedValue(coupon),
      updateOne: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
      exists: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation((doc) => Promise.resolve(doc)),
      find: jest.fn().mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue([]),
        }),
      }),
    };
    return { service: new CouponsService(model as never), model };
  }

  function usableCoupon(overrides: Record<string, unknown> = {}) {
    return {
      _id: 'c1',
      code: 'SUMMER10',
      type: CouponType.PERCENT,
      value: 10,
      minSubtotalMinor: 0,
      redemptions: 0,
      isActive: true,
      ...overrides,
    };
  }

  describe('discountFor', () => {
    it('takes a percentage of the subtotal', () => {
      expect(discountFor({ type: CouponType.PERCENT, value: 10 }, 74000)).toBe(
        7400,
      );
    });

    it('rounds a percentage to whole piastres', () => {
      // 10% of 74999 is 7499.9 — a fractional piastre is not a thing that
      // can be charged, and truncating would favour the customer silently.
      expect(discountFor({ type: CouponType.PERCENT, value: 10 }, 74999)).toBe(
        7500,
      );
    });

    it('never exceeds the basket', () => {
      // A 200 EGP code against a 150 EGP basket is a 150 EGP discount, not
      // a 50 EGP refund.
      expect(discountFor({ type: CouponType.FIXED, value: 20000 }, 15000)).toBe(
        15000,
      );
    });
  });

  describe('validation', () => {
    it('matches the code case-insensitively', async () => {
      const { service, model } = buildService(usableCoupon());
      await service.priceFor('  summer10 ', 74000);
      // A code is read off a post and typed by hand; requiring the exact
      // case it was created in would fail for no reason.
      expect(model.findOne).toHaveBeenCalledWith({ code: 'SUMMER10' });
    });

    it('reports an unknown code as not found', async () => {
      const { service } = buildService(null);
      await expect(service.priceFor('NOPE', 74000)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('refuses a deactivated code', async () => {
      const { service } = buildService(usableCoupon({ isActive: false }));
      await expect(service.priceFor('SUMMER10', 74000)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('refuses a code whose window has not opened', async () => {
      const tomorrow = new Date(Date.now() + 86_400_000);
      const { service } = buildService(usableCoupon({ startsAt: tomorrow }));
      await expect(service.priceFor('SUMMER10', 74000)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('refuses an expired code', async () => {
      const yesterday = new Date(Date.now() - 86_400_000);
      const { service } = buildService(usableCoupon({ endsAt: yesterday }));
      await expect(service.priceFor('SUMMER10', 74000)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('refuses a code that has been fully redeemed', async () => {
      const { service } = buildService(
        usableCoupon({ maxRedemptions: 5, redemptions: 5 }),
      );
      await expect(service.priceFor('SUMMER10', 74000)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('says what the minimum is rather than just refusing', async () => {
      const { service } = buildService(
        usableCoupon({ minSubtotalMinor: 100000 }),
      );
      // "Invalid code" would leave the customer with nothing to act on;
      // the threshold is the one fact that makes it solvable.
      await expect(service.priceFor('SUMMER10', 74000)).rejects.toThrow(
        '1000.00 EGP',
      );
    });

    it('compares the minimum against the subtotal, not the total', async () => {
      const { service } = buildService(
        usableCoupon({ minSubtotalMinor: 74000 }),
      );
      // Passing exactly the threshold qualifies. If shipping counted, the
      // same basket would qualify in Aswan and not in Cairo.
      await expect(service.priceFor('SUMMER10', 74000)).resolves.toEqual({
        code: 'SUMMER10',
        discountMinor: 7400,
      });
    });
  });

  describe('claiming', () => {
    it('takes the redemption with a guarded update, not a read-then-write', async () => {
      const { service, model } = buildService(usableCoupon());

      await service.claim('SUMMER10', 74000);

      const [filter, update] = model.findOneAndUpdate.mock.calls[0];
      // The same conditions that made it usable are re-asserted in the
      // write, so two checkouts racing for a limited code's last
      // redemption cannot both succeed.
      expect(filter.code).toBe('SUMMER10');
      expect(filter.isActive).toBe(true);
      expect(update).toEqual({ $inc: { redemptions: 1 } });
    });

    it('tells the loser of a race that the code is gone', async () => {
      const { service, model } = buildService(usableCoupon());
      // The guarded update matched nothing — someone else took the last one
      // between the read and the write.
      model.findOneAndUpdate.mockResolvedValue(null);

      await expect(service.claim('SUMMER10', 74000)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('refuses to claim a code that would not price', async () => {
      const { service, model } = buildService(
        usableCoupon({ isActive: false }),
      );

      await expect(service.claim('SUMMER10', 74000)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(model.findOneAndUpdate).not.toHaveBeenCalled();
    });

    it('floors a release at zero so it cannot mint a redemption', async () => {
      const { service, model } = buildService(usableCoupon());

      await service.release('summer10');

      const [filter, update] = model.updateOne.mock.calls[0];
      expect(filter).toEqual({ code: 'SUMMER10', redemptions: { $gt: 0 } });
      expect(update).toEqual({ $inc: { redemptions: -1 } });
    });
  });

  describe('admin writes', () => {
    it('refuses a percentage above 100', async () => {
      const { service } = buildService(null);
      await expect(
        service.create({ code: 'HALF', type: CouponType.PERCENT, value: 150 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('allows a fixed amount above 100, which is 1.00 EGP not 100%', async () => {
      const { service } = buildService(null);
      await expect(
        service.create({ code: 'FLAT', type: CouponType.FIXED, value: 15000 }),
      ).resolves.toMatchObject({ value: 15000 });
    });

    it('refuses an end date at or before the start', async () => {
      const { service } = buildService(null);
      const day = new Date('2026-06-01');
      await expect(
        service.create({
          code: 'WINDOW',
          type: CouponType.FIXED,
          value: 5000,
          startsAt: day,
          endsAt: day,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('stores the code upper-cased', async () => {
      const { service, model } = buildService(null);
      await service.create({
        code: 'summer-10',
        type: CouponType.FIXED,
        value: 5000,
      });
      expect(model.create.mock.calls[0][0].code).toBe('SUMMER-10');
    });

    it('rejects a duplicate code', async () => {
      const { service, model } = buildService(null);
      model.exists.mockResolvedValue({ _id: 'c1' });

      await expect(
        service.create({ code: 'SUMMER10', type: CouponType.FIXED, value: 1 }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('refuses to rename a code customers already hold', async () => {
      const { service } = buildService(usableCoupon());
      await expect(
        service.update('c1', {
          code: 'DIFFERENT',
          type: CouponType.PERCENT,
          value: 10,
        }),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });
});
