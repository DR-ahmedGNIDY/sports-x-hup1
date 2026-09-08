import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Types } from 'mongoose';
import { OrderStatus } from '../order-status.enum';
import { OrdersService } from './orders.service';

describe('OrdersService', () => {
  const PRODUCT_ID = new Types.ObjectId();
  const VARIANT_ID = new Types.ObjectId();

  function buildProduct(stock: number) {
    return {
      _id: PRODUCT_ID,
      title: { en: 'Black Cargo Shorts', ar: 'شورت كارجو أسود' },
      priceMinor: 74000,
      images: [{ publicId: 'p', secureUrl: 'https://img/1.jpg' }],
      variants: [
        {
          _id: VARIANT_ID,
          size: 'L',
          colour: 'black',
          stock,
          // `_id.equals` is what the service matches on.
        },
      ],
    };
  }

  function buildService(product: unknown = buildProduct(10)) {
    const orderModel = {
      create: jest.fn().mockImplementation((doc) => Promise.resolve(doc)),
      findById: jest.fn().mockResolvedValue(null),
      findOne: jest.fn().mockResolvedValue(null),
      find: jest.fn(),
      countDocuments: jest.fn(),
    };
    const productModel = {
      find: jest.fn().mockReturnValue({
        exec: jest.fn().mockResolvedValue(product ? [product] : []),
      }),
      updateOne: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
    };
    const shipping = {
      findActiveByCodeOrThrow: jest.fn().mockResolvedValue({
        code: 'cairo',
        name: { en: 'Cairo', ar: 'القاهرة' },
        feeMinor: 5500,
      }),
    };
    const publicCodes = {
      allocate: jest.fn().mockResolvedValue('ORD-000001'),
    };
    const service = new OrdersService(
      orderModel as never,
      productModel as never,
      shipping as never,
      publicCodes as never,
    );
    return { service, orderModel, productModel, shipping, publicCodes };
  }

  const address = {
    fullName: 'Ahmed Gnidy',
    phone: '01012345678',
    governorateCode: 'cairo',
    city: 'Nasr City',
    street: '12 Some Street',
  };

  function orderDto(lines: Array<{ quantity: number }>) {
    return {
      email: 'Buyer@Example.com',
      address,
      lines: lines.map((line) => ({
        productId: PRODUCT_ID.toString(),
        variantId: VARIANT_ID.toString(),
        quantity: line.quantity,
      })),
    };
  }

  describe('pricing', () => {
    it('prices every line from the database, ignoring anything the client sent', async () => {
      const { service, orderModel } = buildService();

      // The DTO has no price field at all; this asserts the amount that
      // lands on the order is the product's own.
      await service.create(orderDto([{ quantity: 2 }]));

      const created = orderModel.create.mock.calls[0][0];
      expect(created.lines[0].unitPriceMinor).toBe(74000);
      expect(created.subtotalMinor).toBe(148000);
    });

    it('adds the governorate fee resolved on the server, not one supplied', async () => {
      const { service, orderModel, shipping } = buildService();

      await service.create(orderDto([{ quantity: 1 }]));

      expect(shipping.findActiveByCodeOrThrow).toHaveBeenCalledWith('cairo');
      const created = orderModel.create.mock.calls[0][0];
      expect(created.shippingFeeMinor).toBe(5500);
      expect(created.totalMinor).toBe(74000 + 5500);
    });

    it('snapshots the title and image so a later edit cannot rewrite the receipt', async () => {
      const { service, orderModel } = buildService();

      await service.create(orderDto([{ quantity: 1 }]));

      const line = orderModel.create.mock.calls[0][0].lines[0];
      expect(line.title).toEqual({
        en: 'Black Cargo Shorts',
        ar: 'شورت كارجو أسود',
      });
      expect(line.imageUrl).toBe('https://img/1.jpg');
      expect(line.size).toBe('L');
    });

    it('rejects a line whose product is inactive or gone', async () => {
      const { service } = buildService(null);
      await expect(
        service.create(orderDto([{ quantity: 1 }])),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('stock', () => {
    it('merges duplicate lines so a split cart cannot oversell', async () => {
      const { service, productModel } = buildService();

      // Two lines of 3 for the same variant. Reserved separately, each
      // passes its own `stock >= 3` test even when only 5 remain.
      await service.create(orderDto([{ quantity: 3 }, { quantity: 3 }]));

      expect(productModel.updateOne).toHaveBeenCalledTimes(1);
      const [, update] = productModel.updateOne.mock.calls[0];
      expect(update).toEqual({ $inc: { 'variants.$.stock': -6 } });
    });

    it('decrements conditionally, so the loser of a race is told it sold out', async () => {
      const { service, productModel } = buildService();
      // The conditional update matched nothing — someone else took the last
      // one between the read and the write.
      productModel.updateOne.mockResolvedValue({ modifiedCount: 0 });

      await expect(
        service.create(orderDto([{ quantity: 1 }])),
      ).rejects.toBeInstanceOf(ConflictException);

      const [filter] = productModel.updateOne.mock.calls[0];
      expect(filter.variants.$elemMatch.stock).toEqual({ $gte: 1 });
    });

    it('gives back stock it already reserved when the order write fails', async () => {
      const { service, orderModel, productModel } = buildService();
      orderModel.create.mockRejectedValue(new Error('mongo is down'));

      await expect(service.create(orderDto([{ quantity: 4 }]))).rejects.toThrow(
        'mongo is down',
      );

      // No transaction is available on a standalone MongoDB, so the
      // compensating write is the only thing standing between a failed
      // checkout and stock held by an order that does not exist.
      const releasing = productModel.updateOne.mock.calls.at(-1);
      expect(releasing?.[1]).toEqual({ $inc: { 'variants.$.stock': 4 } });
    });
  });

  describe('guest checkout', () => {
    it('records no userId when there is no session', async () => {
      const { service, orderModel } = buildService();
      await service.create(orderDto([{ quantity: 1 }]));
      expect(orderModel.create.mock.calls[0][0].userId).toBeUndefined();
    });

    it('attaches the order to the account when there is one', async () => {
      const { service, orderModel } = buildService();
      const userId = new Types.ObjectId().toString();

      await service.create(orderDto([{ quantity: 1 }]), userId);

      expect(orderModel.create.mock.calls[0][0].userId.toString()).toBe(userId);
    });

    it('requires the email as well as the order number to track', async () => {
      const { service, orderModel } = buildService();
      orderModel.findOne.mockResolvedValue({ orderNumber: 'ORD-000001' });

      await service.trackForGuest('ord-000001', ' Buyer@Example.com ');

      // Both halves are matched, and both are normalised — the number is
      // quoted by hand and the email is typed.
      expect(orderModel.findOne).toHaveBeenCalledWith({
        orderNumber: 'ORD-000001',
        email: 'buyer@example.com',
      });
    });

    it('answers not-found for a wrong email rather than confirming the order exists', async () => {
      const { service, orderModel } = buildService();
      orderModel.findOne.mockResolvedValue(null);

      await expect(
        service.trackForGuest('ORD-000001', 'someone@else.com'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects a malformed order number without touching the database', async () => {
      const { service, orderModel } = buildService();

      await expect(
        service.trackForGuest('not-an-order', 'buyer@example.com'),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(orderModel.findOne).not.toHaveBeenCalled();
    });
  });

  describe('ownership', () => {
    it('refuses to hand one account an order belonging to another', async () => {
      const { service, orderModel } = buildService();
      orderModel.findById.mockResolvedValue({
        userId: new Types.ObjectId(),
      });

      await expect(
        service.findOwnedByUserOrThrow('o1', new Types.ObjectId().toString()),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('refuses a signed-in user access to a guest order by id', async () => {
      const { service, orderModel } = buildService();
      orderModel.findById.mockResolvedValue({ userId: undefined });

      await expect(
        service.findOwnedByUserOrThrow('o1', new Types.ObjectId().toString()),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('status transitions', () => {
    function buildOrder(status: OrderStatus) {
      const order = {
        status,
        lines: [{ productId: PRODUCT_ID, variantId: VARIANT_ID, quantity: 2 }],
        save: jest.fn(),
      };
      order.save.mockResolvedValue(order);
      return order;
    }

    it('refuses a move that is not on the allowed path', async () => {
      const { service, orderModel } = buildService();
      orderModel.findById.mockResolvedValue(buildOrder(OrderStatus.DELIVERED));

      await expect(
        service.updateStatus('o1', OrderStatus.PENDING),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuses to cancel an order already with the courier', async () => {
      const { service, orderModel } = buildService();
      orderModel.findById.mockResolvedValue(buildOrder(OrderStatus.SHIPPED));

      await expect(
        service.updateStatus('o1', OrderStatus.CANCELLED),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('returns stock when cancelling before dispatch', async () => {
      const { service, orderModel, productModel } = buildService();
      const order = buildOrder(OrderStatus.CONFIRMED);
      orderModel.findById.mockResolvedValue(order);

      await service.updateStatus('o1', OrderStatus.CANCELLED);

      expect(productModel.updateOne).toHaveBeenCalledWith(
        { _id: PRODUCT_ID, 'variants._id': VARIANT_ID },
        { $inc: { 'variants.$.stock': 2 } },
      );
      expect(order.status).toBe(OrderStatus.CANCELLED);
    });

    it('does not return stock when merely advancing the order', async () => {
      const { service, orderModel, productModel } = buildService();
      orderModel.findById.mockResolvedValue(buildOrder(OrderStatus.CONFIRMED));

      await service.updateStatus('o1', OrderStatus.SHIPPED);

      expect(productModel.updateOne).not.toHaveBeenCalled();
    });

    it('is a no-op when the status is already the requested one', async () => {
      const { service, orderModel } = buildService();
      const order = buildOrder(OrderStatus.SHIPPED);
      orderModel.findById.mockResolvedValue(order);

      await service.updateStatus('o1', OrderStatus.SHIPPED);

      // Re-cancelling a cancelled order must not release its stock twice;
      // returning early is what prevents that.
      expect(order.save).not.toHaveBeenCalled();
    });
  });
});
