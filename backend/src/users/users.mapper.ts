import { UserDocument } from './schemas/user.schema';

export interface PublicUser {
  id: string;
  email?: string;
  phone?: string;
  role: string;
  status: string;
  // Absent when the account is active, or when the suspension is permanent
  // (there is no date to wait for) — see `User.suspendedUntil`.
  suspendedUntil?: Date;
  isModerator: boolean;
  createdAt: Date;
}

// Strips passwordHash — the API must never echo it back, even accidentally.
// `suspensionReason` is admin-only and is not part of this view; the admin
// dashboard reads it through `toAdminUser`.
export function toPublicUser(user: UserDocument): PublicUser {
  return {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role,
    status: user.status,
    suspendedUntil: user.suspendedUntil,
    isModerator: user.isModerator ?? false,
    createdAt: (user as UserDocument & { createdAt: Date }).createdAt,
  };
}

export interface AdminUser extends PublicUser {
  suspensionReason?: string;
}

// The admin dashboard's view: everything `toPublicUser` exposes plus the
// internal note behind a suspension, which the suspended user never sees.
export function toAdminUser(user: UserDocument): AdminUser {
  return { ...toPublicUser(user), suspensionReason: user.suspensionReason };
}
