import { PlayerSubscriptionDocument } from './schemas/player-subscription.schema';

export function toSubscriptionView(subscription: PlayerSubscriptionDocument) {
  return {
    id: subscription._id.toString(),
    playerUserId: subscription.playerUserId.toString(),
    plan: subscription.plan,
    startDate: subscription.startDate,
    endDate: subscription.endDate,
    amountMinor: subscription.amountMinor,
    paidMinor: subscription.paidMinor,
    notes: subscription.notes,
    lastReminderAt: subscription.lastReminderAt,
  };
}

export function toSubscriptionViewOrNull(
  subscription: PlayerSubscriptionDocument | null,
) {
  return subscription ? toSubscriptionView(subscription) : null;
}
