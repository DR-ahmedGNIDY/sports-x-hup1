import { UnauthorizedException } from '@nestjs/common';
import { OptionalJwtAuthGuard } from './optional-jwt-auth.guard';

// This guard is what makes guest checkout possible, so its failure mode is
// not a 401 — it is a storefront that silently refuses anonymous orders.
describe('OptionalJwtAuthGuard', () => {
  const context = {} as never;

  it('lets a request through when passport rejects it', async () => {
    const guard = new OptionalJwtAuthGuard();
    jest
      .spyOn(
        Object.getPrototypeOf(Object.getPrototypeOf(guard)) as {
          canActivate: () => Promise<boolean>;
        },
        'canActivate',
      )
      .mockRejectedValue(new UnauthorizedException());

    // A guest has no token at all; that is the normal case here.
    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('lets a request through when passport accepts it', async () => {
    const guard = new OptionalJwtAuthGuard();
    jest
      .spyOn(
        Object.getPrototypeOf(Object.getPrototypeOf(guard)) as {
          canActivate: () => Promise<boolean>;
        },
        'canActivate',
      )
      .mockResolvedValue(true);

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  describe('handleRequest', () => {
    it('returns the user when there is one, so the order is attached', () => {
      const guard = new OptionalJwtAuthGuard();
      const user = { sub: 'u1', role: 'PLAYER' };
      expect(guard.handleRequest(null, user)).toBe(user);
    });

    it('returns null instead of throwing for an expired or invalid token', () => {
      const guard = new OptionalJwtAuthGuard();
      // The base guard would throw here. A customer whose session quietly
      // expired in another tab must still be able to complete a purchase —
      // as a guest.
      expect(
        guard.handleRequest(new UnauthorizedException(), undefined),
      ).toBeNull();
    });
  });
});
