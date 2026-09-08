import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import {
  PublicCodePrefix,
  PublicCodesService,
} from '../../public-codes/public-codes.service';
import {
  ALLOWED_STATUS_TRANSITIONS,
  OrderStatus,
  releasesStock,
} from '../order-status.enum';
import { StoreOrder, StoreOrderDocument } from '../schemas/order.schema';
import { StoreProduct } from '../schemas/product.schema';
import { ShippingService } from '../shipping/shipping.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { ListOrdersDto } from './dto/list-orders.dto';

const ORDER_LIST_PAGE_SIZE = 20;

/** One variant and how many of it, after duplicate lines are merged. */
interface StockClaim {
  productId: Types.ObjectId;
  variantId: Types.ObjectId;
  quantity: number;
}

export interface OrderPaginatedResult {
  items: StoreOrderDocument[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(StoreOrder.name)
    private readonly orderModel: Model<StoreOrder>,
    @InjectModel(StoreProduct.name)
    private readonly productModel: Model<StoreProduct>,
    private readonly shipping: ShippingService,
    private readonly publicCodes: PublicCodesService,
  ) {}

  // `userId` is undefined for a guest — the checkout endpoint is reachable
  // without a session on purpose, and the only difference it makes is
  // whether the order joins someone's order history.
  async create(
    dto: CreateOrderDto,
    userId?: string,
  ): Promise<StoreOrderDocument> {
    const zone = await this.shipping.findActiveByCodeOrThrow(
      dto.address.governorateCode,
    );

    // Two lines for the same variant are merged before anything is checked.
    // Left separate, each would pass its own `stock >= quantity` test while
    // together exceeding it — the classic way a cart oversells a last item.
    const claims = this.mergeClaims(dto);
    const priced = await this.priceLines(claims);

    const subtotalMinor = priced.lines.reduce(
      (sum, line) => sum + line.unitPriceMinor * line.quantity,
      0,
    );

    // Stock is taken before the order document exists, so an order can never
    // be recorded against stock that was not actually reserved.
    const reserved = await this.reserveStock(claims);

    try {
      const orderNumber = await this.publicCodes.allocate(
        PublicCodePrefix.ORDER,
      );
      return await this.orderModel.create({
        orderNumber,
        userId: userId ? new Types.ObjectId(userId) : undefined,
        email: dto.email,
        lines: priced.lines,
        address: {
          ...dto.address,
          governorateCode: zone.code,
          governorateName: { en: zone.name.en, ar: zone.name.ar },
        },
        subtotalMinor,
        shippingFeeMinor: zone.feeMinor,
        totalMinor: subtotalMinor + zone.feeMinor,
        status: OrderStatus.PENDING,
      });
    } catch (error) {
      // The reservation and the order are two writes that this deployment
      // cannot wrap in a transaction — MongoDB runs standalone here, not as
      // a replica set (see PublicCodesService for the same constraint). So
      // the failure is compensated explicitly: without this, a failed order
      // would leave its stock permanently held by nothing.
      await this.releaseStock(reserved);
      throw error;
    }
  }

  private mergeClaims(dto: CreateOrderDto): StockClaim[] {
    const byVariant = new Map<string, StockClaim>();
    for (const line of dto.lines) {
      const existing = byVariant.get(line.variantId);
      if (existing) {
        existing.quantity += line.quantity;
        continue;
      }
      byVariant.set(line.variantId, {
        productId: new Types.ObjectId(line.productId),
        variantId: new Types.ObjectId(line.variantId),
        quantity: line.quantity,
      });
    }
    return [...byVariant.values()];
  }

  // Every amount on the order comes from here — the database — and none from
  // the request body. This is the single place that decides what a customer
  // is charged.
  private async priceLines(claims: StockClaim[]) {
    const products = await this.productModel
      .find({
        _id: { $in: claims.map((claim) => claim.productId) },
        isActive: true,
      })
      .exec();

    const byId = new Map(
      products.map((product) => [product._id.toString(), product]),
    );

    const lines = claims.map((claim) => {
      const product = byId.get(claim.productId.toString());
      if (!product) {
        throw new BadRequestException(
          'One of the products in your cart is no longer available.',
        );
      }

      const variant = product.variants.find((candidate) =>
        candidate._id?.equals(claim.variantId),
      );
      if (!variant) {
        throw new BadRequestException(
          'One of the options in your cart is no longer available.',
        );
      }

      return {
        productId: product._id,
        variantId: claim.variantId,
        title: { en: product.title.en, ar: product.title.ar },
        size: variant.size,
        colour: variant.colour,
        imageUrl: product.images[0]?.secureUrl,
        quantity: claim.quantity,
        unitPriceMinor: product.priceMinor,
      };
    });

    return { lines };
  }

  // Each claim is one conditional atomic update: it decrements only if that
  // variant still holds enough. Two customers racing for the last item both
  // reach this, and exactly one update matches — the other sees
  // `modifiedCount` of 0 and is told the item sold out, rather than both
  // succeeding on a stale read.
  private async reserveStock(claims: StockClaim[]): Promise<StockClaim[]> {
    const reserved: StockClaim[] = [];

    for (const claim of claims) {
      const result = await this.productModel.updateOne(
        {
          _id: claim.productId,
          variants: {
            $elemMatch: {
              _id: claim.variantId,
              stock: { $gte: claim.quantity },
            },
          },
        },
        { $inc: { 'variants.$.stock': -claim.quantity } },
      );

      if (result.modifiedCount !== 1) {
        // Give back whatever this attempt already took before failing, so a
        // partly-filled cart does not strand stock.
        await this.releaseStock(reserved);
        throw new ConflictException(
          'One of the items in your cart just sold out.',
        );
      }
      reserved.push(claim);
    }

    return reserved;
  }

  // Compensation, not a transaction rollback. Unconditional on purpose: the
  // stock is being returned, and a condition that failed to match would lose
  // it silently.
  private async releaseStock(claims: StockClaim[]): Promise<void> {
    for (const claim of claims) {
      await this.productModel.updateOne(
        { _id: claim.productId, 'variants._id': claim.variantId },
        { $inc: { 'variants.$.stock': claim.quantity } },
      );
    }
  }

  async listForAdmin(dto: ListOrdersDto): Promise<OrderPaginatedResult> {
    const filter: FilterQuery<StoreOrder> = {};
    if (dto.status) filter.status = dto.status;
    return this.paginate(filter, dto.page ?? 1);
  }

  async listForUser(
    userId: string,
    dto: ListOrdersDto,
  ): Promise<OrderPaginatedResult> {
    const filter: FilterQuery<StoreOrder> = {
      userId: new Types.ObjectId(userId),
    };
    if (dto.status) filter.status = dto.status;
    return this.paginate(filter, dto.page ?? 1);
  }

  private async paginate(
    filter: FilterQuery<StoreOrder>,
    page: number,
  ): Promise<OrderPaginatedResult> {
    const skip = (page - 1) * ORDER_LIST_PAGE_SIZE;
    const [items, total] = await Promise.all([
      this.orderModel
        .find(filter)
        .sort({ createdAt: -1, _id: 1 })
        .skip(skip)
        .limit(ORDER_LIST_PAGE_SIZE)
        .exec(),
      this.orderModel.countDocuments(filter).exec(),
    ]);
    return { items, page, pageSize: ORDER_LIST_PAGE_SIZE, total };
  }

  async findByIdOrThrow(id: string): Promise<StoreOrderDocument> {
    const order = await this.orderModel.findById(id);
    if (!order) throw new NotFoundException('Order not found.');
    return order;
  }

  // A signed-in customer reading one of their own orders. Ownership is
  // checked here rather than trusted from the route, so a valid session for
  // one account cannot read another account's order by id.
  async findOwnedByUserOrThrow(
    id: string,
    userId: string,
  ): Promise<StoreOrderDocument> {
    const order = await this.findByIdOrThrow(id);
    if (!order.userId || order.userId.toString() !== userId) {
      throw new ForbiddenException('This order belongs to another account.');
    }
    return order;
  }

  // The guest equivalent. Order numbers are sequential, so the number alone
  // would let anyone walk the whole order book; the email it was placed with
  // is required as the second half of the credential. A mismatch answers
  // "not found" rather than "wrong email", which would confirm that the
  // order number exists.
  async trackForGuest(
    orderNumber: string,
    email: string,
  ): Promise<StoreOrderDocument> {
    const normalized = PublicCodesService.normalizeFor(
      orderNumber,
      PublicCodePrefix.ORDER,
    );
    if (!normalized) throw new NotFoundException('Order not found.');

    const order = await this.orderModel.findOne({
      orderNumber: normalized,
      email: email.trim().toLowerCase(),
    });
    if (!order) throw new NotFoundException('Order not found.');
    return order;
  }

  async updateStatus(
    id: string,
    status: OrderStatus,
  ): Promise<StoreOrderDocument> {
    const order = await this.findByIdOrThrow(id);
    if (order.status === status) return order;

    if (!ALLOWED_STATUS_TRANSITIONS[order.status].includes(status)) {
      throw new BadRequestException(
        `An order cannot move from ${order.status} to ${status}.`,
      );
    }

    // Stock goes back before the status is written: if the release fails,
    // the order stays cancellable rather than being marked cancelled with
    // its stock still held.
    if (releasesStock(order.status, status)) {
      await this.releaseStock(
        order.lines.map((line) => ({
          productId: line.productId,
          variantId: line.variantId,
          quantity: line.quantity,
        })),
      );
    }

    order.status = status;
    return order.save();
  }
}
