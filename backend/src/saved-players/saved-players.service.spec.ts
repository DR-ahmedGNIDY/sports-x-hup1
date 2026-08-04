import { ConflictException, NotFoundException } from '@nestjs/common';
import { PlayersService } from '../players/players.service';
import { SavedPlayersService } from './saved-players.service';

describe('SavedPlayersService', () => {
  function buildService(overrides: {
    create?: jest.Mock;
    deleteOne?: jest.Mock;
  }) {
    const model = {
      create: overrides.create ?? jest.fn(),
      deleteOne: overrides.deleteOne ?? jest.fn(),
    };
    const playersService = {
      findPublicByIdOrThrow: jest.fn().mockResolvedValue({}),
    } as unknown as PlayersService;
    const service = new SavedPlayersService(model as never, playersService);
    return { service, playersService };
  }

  it('rejects saving a player that is not public before touching the database', async () => {
    const model = { create: jest.fn(), deleteOne: jest.fn() };
    const playersService = {
      findPublicByIdOrThrow: jest
        .fn()
        .mockRejectedValue(new NotFoundException()),
    } as unknown as PlayersService;
    const service = new SavedPlayersService(model as never, playersService);

    await expect(service.save('club1', 'player1')).rejects.toThrow(
      NotFoundException,
    );
    expect(model.create).not.toHaveBeenCalled();
  });

  it('turns a duplicate-key error into a ConflictException', async () => {
    const { service } = buildService({
      create: jest.fn().mockRejectedValue({ code: 11000 }),
    });

    await expect(service.save('club1', 'player1')).rejects.toThrow(
      ConflictException,
    );
  });

  it('throws NotFoundException when unsaving a player that was never saved', async () => {
    const { service } = buildService({
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 0 }),
    });

    await expect(service.unsave('club1', 'player1')).rejects.toThrow(
      NotFoundException,
    );
  });
});
