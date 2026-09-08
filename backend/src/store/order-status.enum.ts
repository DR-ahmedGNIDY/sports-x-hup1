/// Where an order is in its life. Cash on delivery has no payment step of
/// its own, so the money is collected inside DELIVERED rather than being a
/// state — adding a payment gateway later inserts states before CONFIRMED
/// without disturbing these.
export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  SHIPPED = 'shipped',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
}

/// Which moves the merchant is allowed to make from each state.
///
/// Encoded as data rather than as conditionals in the service because the
/// illegal transitions are the point: a DELIVERED order that can slide back
/// to PENDING makes the status field useless for accounting, and an order
/// cancelled after it shipped has stock implications nobody reconciled.
export const ALLOWED_STATUS_TRANSITIONS: Readonly<
  Record<OrderStatus, readonly OrderStatus[]>
> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
  // Once it is with the courier, cancelling is a return, which is a
  // different process with different stock and money consequences.
  [OrderStatus.SHIPPED]: [OrderStatus.DELIVERED],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
};

/// Cancelling is the only transition that puts stock back, and only from a
/// state the goods never left the warehouse in.
export function releasesStock(from: OrderStatus, to: OrderStatus): boolean {
  return (
    to === OrderStatus.CANCELLED &&
    (from === OrderStatus.PENDING || from === OrderStatus.CONFIRMED)
  );
}
