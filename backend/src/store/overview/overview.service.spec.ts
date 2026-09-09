import { OrderStatus } from '../order-status.enum';
import { StoreOverviewService, startOfToday } from './overview.service';

describe('StoreOverviewService', () => {
  function buildService() {
    const orderModel = {
      aggregate: jest.fn().mockReturnValue({
        exec: jest.fn().mockResolvedValue([]),
      }),
      countDocuments: jest
        .fn()
        .mockReturnValue({ exec: jest.fn().mockResolvedValue(0) }),
    };
    const productModel = {
      countDocuments: jest
        .fn()
        .mockReturnValue({ exec: jest.fn().mockResolvedValue(0) }),
    };
    const service = new StoreOverviewService(
      orderModel as never,
      productModel as never,
    );
    return { service, orderModel, productModel };
  }

  describe('startOfToday', () => {
    it('is local midnight, not UTC midnight', () => {
      const midday = new Date(2026, 8, 9, 12, 30);
      const start = startOfToday(midday);
      // The merchant and the server are both in Egypt. A UTC boundary would
      // put the early morning's orders on the previous day.
      expect(start.getHours()).toBe(0);
      expect(start.getDate()).toBe(9);
      expect(start.getMonth()).toBe(8);
    });
  });

  describe('today', () => {
    it('excludes cancelled orders from the count and the money', async () => {
      const { service, orderModel } = buildService();

      await service.summarise();

      const pipeline = orderModel.aggregate.mock.calls[0][0] as Array<
        Record<string, Record<string, unknown>>
      >;
      // A cancelled order was never collected; counting it would make a bad
      // day look busy and overstate the takings.
      expect(pipeline[0].$match.status).toEqual({
        $ne: OrderStatus.CANCELLED,
      });
    });

    it('reports zeroes when nothing has been ordered yet', async () => {
      const { service } = buildService();
      // An empty pipeline returns no rows at all, not a row of zeroes.
      const overview = await service.summarise();
      expect(overview.ordersToday).toBe(0);
      expect(overview.revenueTodayMinor).toBe(0);
    });

    it('reads the aggregated totals when there are orders', async () => {
      const { service, orderModel } = buildService();
      orderModel.aggregate.mockReturnValue({
        exec: jest.fn().mockResolvedValue([{ count: 3, revenueMinor: 241500 }]),
      });

      const overview = await service.summarise();

      expect(overview.ordersToday).toBe(3);
      expect(overview.revenueTodayMinor).toBe(241500);
    });
  });

  describe('stock counts', () => {
    it('counts a product out of stock only when no variant has any', async () => {
      const { service, productModel } = buildService();

      await service.summarise();

      const filters = productModel.countDocuments.mock.calls.map(
        (call) => call[0] as Record<string, unknown>,
      );
      const outOfStock = filters.find(
        (f) => '$not' in ((f.variants ?? {}) as object),
      );

      // The bug this guards: `variants.stock: 0` would match any product
      // with one sold-out size, which is most of them.
      expect(outOfStock?.variants).toEqual({
        $not: { $elemMatch: { stock: { $gt: 0 } } },
      });
    });

    it('counts low stock as a variant running out while still sellable', async () => {
      const { service, productModel } = buildService();

      await service.summarise();

      const filters = productModel.countDocuments.mock.calls.map(
        (call) => call[0] as Record<string, unknown>,
      );
      const lowStock = filters.find(
        (f) => '$elemMatch' in ((f.variants ?? {}) as object),
      );

      // `$gt: 0` matters: a sold-out variant belongs in the out-of-stock
      // count, not in the reorder list.
      expect(lowStock?.variants).toEqual({
        $elemMatch: { stock: { $gt: 0, $lte: 3 } },
      });
    });

    it('only counts listed products', async () => {
      const { service, productModel } = buildService();

      await service.summarise();

      for (const [filter] of productModel.countDocuments.mock.calls) {
        // An unlisted product's stock is not the merchant's problem today.
        expect((filter as { isActive: boolean }).isActive).toBe(true);
      }
    });
  });
});
