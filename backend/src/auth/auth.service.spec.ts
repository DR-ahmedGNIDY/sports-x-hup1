import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { UserRole, UserStatus } from '../users/schemas/user.schema';

describe('AuthService', () => {
  const fakeConfig = {
    get: (key: string) =>
      key === 'JWT_REFRESH_SECRET' ? 'test-secret' : undefined,
  };
  const fakeJwtService = { sign: jest.fn(() => 'signed.jwt.token') };
  const fakeMailService = { sendPasswordResetEmail: jest.fn() };
  const fakeRefreshTokenModel = {
    create: jest.fn(),
    deleteOne: jest.fn(),
    findOne: jest.fn(),
  };
  const fakePasswordResetTokenModel = {
    create: jest.fn(),
    findOne: jest.fn(),
    deleteMany: jest.fn(),
  };

  let passwordHash: string;
  let fakeUsersService: {
    findByEmailOrPhone: jest.Mock;
    findByIdOrThrow: jest.Mock;
    createPlayerOrClub: jest.Mock;
  };
  let service: AuthService;

  beforeAll(async () => {
    passwordHash = await bcrypt.hash('correct-password', 4);
  });

  beforeEach(() => {
    jest.clearAllMocks();

    const fakeUser = {
      id: 'user-1',
      _id: 'user-1',
      email: 'player@example.com',
      passwordHash,
      role: UserRole.PLAYER,
      status: UserStatus.ACTIVE,
      createdAt: new Date(),
    };

    fakeUsersService = {
      findByEmailOrPhone: jest.fn().mockResolvedValue(fakeUser),
      findByIdOrThrow: jest.fn().mockResolvedValue(fakeUser),
      createPlayerOrClub: jest.fn().mockResolvedValue(fakeUser),
    };

    service = new AuthService(
      fakeUsersService as never,
      fakeJwtService as never,
      fakeMailService as never,
      fakeConfig as never,
      fakeRefreshTokenModel as never,
      fakePasswordResetTokenModel as never,
    );
  });

  it('rejects login with the wrong password', async () => {
    await expect(
      service.login({
        identifier: 'player@example.com',
        password: 'wrong-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(fakeRefreshTokenModel.create).not.toHaveBeenCalled();
  });

  it('rejects login for an identifier that does not exist', async () => {
    fakeUsersService.findByEmailOrPhone.mockResolvedValueOnce(null);
    await expect(
      service.login({
        identifier: 'nobody@example.com',
        password: 'whatever123',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rejects login for a suspended account, even with the correct password', async () => {
    fakeUsersService.findByEmailOrPhone.mockResolvedValueOnce({
      id: 'user-1',
      _id: 'user-1',
      email: 'player@example.com',
      passwordHash,
      role: UserRole.PLAYER,
      status: UserStatus.SUSPENDED,
      createdAt: new Date(),
    });

    await expect(
      service.login({
        identifier: 'player@example.com',
        password: 'correct-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(fakeRefreshTokenModel.create).not.toHaveBeenCalled();
  });

  it('issues an access token and a stored, hashed refresh token on successful login', async () => {
    const result = await service.login({
      identifier: 'player@example.com',
      password: 'correct-password',
    });

    expect(result.accessToken).toBe('signed.jwt.token');
    expect(result.user.email).toBe('player@example.com');
    expect(result.refreshToken).toHaveLength(96); // 48 random bytes, hex-encoded

    expect(fakeRefreshTokenModel.create).toHaveBeenCalledTimes(1);
    const stored = fakeRefreshTokenModel.create.mock.calls[0][0] as {
      tokenHash: string;
    };
    // The raw token is never what gets stored — only its HMAC.
    expect(stored.tokenHash).not.toBe(result.refreshToken);
    expect(stored.tokenHash).toHaveLength(64); // sha256 hex digest
  });
});
