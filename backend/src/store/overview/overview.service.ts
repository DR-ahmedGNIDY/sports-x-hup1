import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { OrderStatus } from '../order-status.enum';
import { StoreOrder } from '../schemas/order.schema';
import { StoreProduct } from '../schemas/product.schema';

/// A variant at or below this is worth flagging before it sells out — early
/// enough to reorder, high enough not to cry wolf on every popular line.
const LOW_STOCK_THRESHOLD = 3;

export interface StoreOverview {
  ordersToday: number;
  revenueTodayMinor: number;
  pendingOrders: number;
  outOfStockProducts: number;
  lowStockProducts: number;
  activeProducts: number;
}

@Injectable()
export class StoreOverviewService {
  constructor(
    @InjectModel(StoreOrder.name)
    private readonly orderModel: Model<StoreOrder>,
    @InjectModel(StoreProduct.name)
    private readonly productModel: Model<StoreProduct>,
  ) {}

  async summarise(): Promise<StoreOverview> {
    const since = startOfToday();

    const [today, pendingOrders, activeProducts, outOfStock, lowStock] =
      await Promise.all([
        this.todayTotals(since),
        this.orderModel.countDocuments({ status: OrderStatus.PENDING }).exec(),
        this.productModel.countDocuments({ isActive: true }).exec(),
        // "Out of stock" is a property of the whole product, not a variant:
        // it means nothing on the page can be bought. `$not $elemMatch` is
        // the way to say "no variant has any" — a plain `variants.stock: 0`
        // would match any product with one sold-out size.
        this.productModel
          .countDocuments({
            isActive: true,
            variants: { $not: { $elemMatch: { stock: { $gt: 0 } } } },
          })
          .exec(),
        // Low stock is the opposite shape: at least one variant is running
        // out while the product as a whole is still sellable, which is
        // exactly the case worth a reorder.
        this.productModel
          .countDocuments({
            isActive: true,
            variants: {
              $elemMatch: { stock: { $gt: 0, $lte: LOW_STOCK_THRESHOLD } },
            },
          })
          .exec(),
      ]);

    return {
      ordersToday: today.count,
      revenueTodayMinor: today.revenueMinor,
      pendingOrders,
      outOfStockProducts: outOfStock,
      lowStockProducts: lowStock,
      activeProducts,
    };
  }

  // Cancelled orders are excluded from both the count and the money: they
  // were never collected, and counting them would make a bad day look busy.
  private async todayTotals(
    since: Date,
  ): Promise<{ count: number; revenueMinor: number }> {
    const [result] = await this.orderModel
      .aggregate<{ count: number; revenueMinor: number }>([
        {
          $match: {
            createdAt: { $gte: since },
            status: { $ne: OrderStatus.CANCELLED },
          },
        },
        {
          $group: {
            _id: null,
            count: { $sum: 1 },
            revenueMinor: { $sum: '$totalMinor' },
          },
        },
      ])
      .exec();

    // No orders yet today is an empty pipeline result, not a zero row.
    return result ?? { count: 0, revenueMinor: 0 };
  }
}

/// Midnight in the server's own timezone. The merchant and the server are
/// both in Egypt, so this is the day they mean; a UTC boundary would move
/// "today" two hours off and make the morning's orders look like
/// yesterday's.
export function startOfToday(now: Date = new Date()): Date {
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}
