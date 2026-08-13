import { UserDocument } from './schemas/user.schema';

export interface PublicUser {
  id: string;
  email?: string;
  phone?: string;
  role: string;
  status: string;
  createdAt: Date;
}

// Strips passwordHash — the API must never echo it back, even accidentally.
export function toPublicUser(user: UserDocument): PublicUser {
  return {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role,
    status: user.status,
    createdAt: (user as UserDocument & { createdAt: Date }).createdAt,
  };
}
