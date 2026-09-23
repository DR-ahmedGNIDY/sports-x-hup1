import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface JwtPayload {
  sub: string; // userId
  email?: string; // absent for club-created players, who log in by phone
  role: string;
  // Community-moderation flag, resolved from the live user record by
  // JwtStrategy on every request rather than signed into the token, so
  // granting or revoking it takes effect immediately instead of when the
  // user's access token next expires.
  isModerator?: boolean;
}

interface RequestWithUser {
  user: JwtPayload;
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtPayload => {
    const request = ctx.switchToHttp().getRequest<RequestWithUser>();
    return request.user;
  },
);
