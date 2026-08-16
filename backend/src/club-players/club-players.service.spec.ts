import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { ClubPlayersService } from './club-players.service';

describe('ClubPlayersService', () => {
  function buildService(
    overrides: {
      clubManagedPlayer?: Record<string, unknown> | null;
      createUser?: Record<string, unknown>;
      findByIdOrThrow?: Record<string, unknown>;
    } = {},
  ) {
    const savedProfile = {
      userId: overrides.createUser?.id ?? 'player-1',
      visibility: 'PRIVATE',
      save: jest.fn().mockResolvedValue(undefined),
    };
    const clubManagedPlayerModel = {
      create: jest.fn().mockResolvedValue({}),
      findOne: jest
        .fn()
        .mockResolvedValue(
          overrides.clubManagedPlayer === undefined
            ? { _id: 'ownership-1', clubId: 'club-1', userId: 'player-1' }
            : overrides.clubManagedPlayer,
        ),
      find: jest.fn().mockReturnValue({
        sort: jest.fn().mockResolvedValue([]),
      }),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const usersService = {
      createClubManagedPlayer: jest
        .fn()
        .mockResolvedValue(
          overrides.createUser ?? { id: 'player-1', phone: '+201111111111' },
        ),
      findByIdOrThrow: jest.fn().mockResolvedValue(
        overrides.findByIdOrThrow ?? {
          id: 'player-1',
          phone: '+201111111111',
        },
      ),
      setPasswordHash: jest.fn(),
    };
    const playersService = {
      updateProfile: jest.fn().mockResolvedValue(savedProfile),
      getOrCreateForUser: jest.fn().mockResolvedValue(savedProfile),
      setProfilePhoto: jest.fn().mockResolvedValue(savedProfile),
      findManyByUserIds: jest.fn().mockResolvedValue([]),
    };

    const service = new ClubPlayersService(
      clubManagedPlayerModel as never,
      usersService as never,
      playersService as never,
    );
    return {
      service,
      clubManagedPlayerModel,
      usersService,
      playersService,
      savedProfile,
    };
  }

  const baseDto = {
    firstName: 'Ahmed',
    lastName: 'Ali',
    phone: '01001234567',
    countryIsoCode: 'EG',
  };

  it('creates a player account with a normalized phone, generated password, and PUBLIC visibility', async () => {
    const { service, usersService, savedProfile, clubManagedPlayerModel } =
      buildService();

    const result = await service.createPlayer('club-1', baseDto as never);

    expect(usersService.createClubManagedPlayer).toHaveBeenCalledWith(
      expect.objectContaining({ phone: '+201001234567' }),
    );
    expect(result.credentials.username).toBe('+201001234567');
    expect(result.credentials.password).toHaveLength(12);
    expect(savedProfile.visibility).toBe('PUBLIC');
    expect(savedProfile.save).toHaveBeenCalled();
    expect(clubManagedPlayerModel.create).toHaveBeenCalledWith(
      expect.objectContaining({ clubId: 'club-1', dialCode: '+20' }),
    );
  });

  it('rejects an unsupported country code', async () => {
    const { service } = buildService();
    await expect(
      service.createPlayer('club-1', {
        ...baseDto,
        countryIsoCode: 'ZZ',
      } as never),
    ).rejects.toThrow();
  });

  it('surfaces the duplicate-phone conflict raised by UsersService', async () => {
    const { service, usersService } = buildService();
    usersService.createClubManagedPlayer.mockRejectedValueOnce(
      new Error('duplicate'),
    );
    await expect(
      service.createPlayer('club-1', baseDto as never),
    ).rejects.toThrow('duplicate');
  });

  it('blocks a club from managing a player it does not own', async () => {
    const { service } = buildService({ clubManagedPlayer: null });
    await expect(
      service.updatePlayer('club-1', 'someone-elses-player', {} as never),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('resends credentials with a freshly generated password for an owned player', async () => {
    const { service, usersService } = buildService();

    const credentials = await service.resendCredentials('club-1', 'player-1');

    expect(credentials.username).toBe('+201111111111');
    expect(credentials.password).toHaveLength(12);
    expect(usersService.setPasswordHash).toHaveBeenCalledWith(
      'player-1',
      expect.any(String),
    );
  });

  it('rejects resending credentials for a player with no phone on file', async () => {
    const { service } = buildService({
      findByIdOrThrow: { id: 'player-1', phone: undefined },
    });
    await expect(
      service.resendCredentials('club-1', 'player-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('removes only the ownership record for a club-owned player', async () => {
    const { service, clubManagedPlayerModel } = buildService();

    await service.removeFromClub('club-1', 'player-1');

    expect(clubManagedPlayerModel.deleteOne).toHaveBeenCalledWith({
      _id: 'ownership-1',
    });
    // The player's own account/profile is never touched by this operation.
    expect(clubManagedPlayerModel.deleteOne).not.toHaveBeenCalledWith(
      expect.objectContaining({ userId: expect.anything() }),
    );
  });

  it('blocks removing a player another club owns', async () => {
    const { service } = buildService({ clubManagedPlayer: null });
    await expect(
      service.removeFromClub('club-1', 'someone-elses-player'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
