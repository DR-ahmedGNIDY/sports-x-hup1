import { NotificationDocument } from './schemas/notification.schema';

// The view carries `params` through untouched and adds no text: rendering is
// the client's job, from the same .arb files as the rest of the app. See the
// schema's comment on why nothing here is a pre-rendered string.
export function toNotificationView(notification: NotificationDocument) {
  return {
    id: notification._id.toString(),
    type: notification.type,
    params: notification.params,
    entityType: notification.entityType,
    entityId: notification.entityId.toString(),
    read: notification.readAt != null,
    readAt: notification.readAt,
    createdAt: (notification as NotificationDocument & { createdAt: Date })
      .createdAt,
  };
}
