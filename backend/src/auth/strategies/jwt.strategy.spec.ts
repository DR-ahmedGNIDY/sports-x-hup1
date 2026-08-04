import { UnauthorizedException } from '@nestjs/common';
import { UserStatus } from '../../users/schemas/user.schema';
import { JwtStrategy } from './jwt.strategy';

describe('JwtStrategy', () => {
  const fakeConfig = { get: () => 'a'.repeat(32) };

  function buildStrategy(user: { status: UserStatus } | null) {
    const usersService = { findById: jest.fn().mockResolvedValue(user) };
    const strategy = new JwtStrategy(
      fakeConfig as never,
      usersService as never,
    );
    return strategy;
  }

  it('rejects a token for a suspended user, even if the token itself is valid', async () => {
    const strategy = buildStrategy({ status: UserStatus.SUSPENDED });

    await expect(
      strategy.validate({ sub: 'user-1', email: 'a@b.com', role: 'PLAYER' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects a token for a user that no longer exists', async () => {
    const strategy = buildStrategy(null);

    await expect(
      strategy.validate({ sub: 'user-1', email: 'a@b.com', role: 'PLAYER' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('accepts a token for an active user', async () => {
    const strategy = buildStrategy({ status: UserStatus.ACTIVE });
    const payload = { sub: 'user-1', email: 'a@b.com', role: 'PLAYER' };

    await expect(strategy.validate(payload)).resolves.toBe(payload);
  });
});
