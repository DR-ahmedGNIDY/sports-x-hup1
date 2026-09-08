import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

// Lets a route serve both a signed-in user and an anonymous one. Store
// checkout is the case that needs it: a guest must be able to order, while a
// signed-in customer's order should still be attached to their account.
//
// A bad or expired token is treated as no token rather than as a 401 — the
// alternative would be a guest checkout that starts failing for anyone whose
// session quietly expired in another tab.
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Populates `request.user` when a valid token is present. The base guard
    // throws for a missing or invalid one, which here is not an error.
    try {
      await super.canActivate(context);
    } catch {
      // Deliberately swallowed — see above.
    }
    return true;
  }

  // Called by the base guard with whatever passport produced. Returning null
  // instead of throwing is what stops an invalid token from ending the
  // request; `canActivate` above still guards the missing-token path, which
  // fails before this is reached.
  handleRequest<TUser>(_err: unknown, user: TUser): TUser | null {
    return user ?? null;
  }
}
