import { NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { PlayersService } from './players.service';
import { ProfileVisibility } from './schemas/player-profile.schema';

describe('PlayersService', () => {
  function buildService(profile: Record<string, unknown> | null) {
    const model = {
      findById: jest.fn().mockResolvedValue(profile),
      findOne: jest.fn().mockResolvedValue(profile),
      create: jest.fn().mockResolvedValue(profile),
    };
    const cloudinary = {} as CloudinaryService;
    const service = new PlayersService(model as never, cloudinary);
    return { service, model };
  }

  it('rejects a non-existent id before querying the database', async () => {
    const { service, model } = buildService(null);

    await expect(service.findPublicByIdOrThrow('not-an-id')).rejects.toThrow(
      NotFoundException,
    );
    expect(model.findById).not.toHaveBeenCalled();
  });

  it('hides a profile whose visibility is PRIVATE from the public lookup', async () => {
    const { service } = buildService({
      visibility: ProfileVisibility.PRIVATE,
    });

    await expect(
      service.findPublicByIdOrThrow(new Types.ObjectId().toString()),
    ).rejects.toThrow(NotFoundException);
  });

  it('returns a profile whose visibility is PUBLIC', async () => {
    const publicProfile = { visibility: ProfileVisibility.PUBLIC };
    const { service } = buildService(publicProfile);

    const result = await service.findPublicByIdOrThrow(
      new Types.ObjectId().toString(),
    );

    expect(result).toBe(publicProfile);
  });
});
