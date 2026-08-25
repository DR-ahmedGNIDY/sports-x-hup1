import { UnauthorizedException } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
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

  // Regression test for CWE-347 / OWASP ASVS 3.5 (algorithm confusion):
  // JwtStrategy must pin `algorithms: ['HS256']` so a token signed with any
  // other algorithm — even using the exact same secret — is rejected by
  // passport-jwt's underlying jsonwebtoken verifier before `validate()` is
  // ever reached.
  it('pins verification to HS256 only, rejecting tokens signed with a different algorithm', () => {
    const strategy = buildStrategy({ status: UserStatus.ACTIVE });
    const secret = 'a'.repeat(32);
    const payload = { sub: 'user-1', email: 'a@b.com', role: 'PLAYER' };

    const hs256Token = jwt.sign(payload, secret, { algorithm: 'HS256' });
    const hs384Token = jwt.sign(payload, secret, { algorithm: 'HS384' });

    const algorithms = (
      strategy as unknown as { _verifOpts: { algorithms: jwt.Algorithm[] } }
    )._verifOpts.algorithms;
    expect(algorithms).toEqual(['HS256']);

    expect(() => jwt.verify(hs256Token, secret, { algorithms })).not.toThrow();
    expect(() => jwt.verify(hs384Token, secret, { algorithms })).toThrow();
  });
});
