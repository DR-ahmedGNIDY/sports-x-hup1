import { NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { PlayersService } from './players.service';
import { MediaType, ProfileVisibility } from './schemas/player-profile.schema';

describe('PlayersService', () => {
  function buildService(
    profile: Record<string, unknown> | null,
    cloudinaryOverrides: Partial<CloudinaryService> = {},
  ) {
    const model = {
      findById: jest.fn().mockResolvedValue(profile),
      findOne: jest.fn().mockResolvedValue(profile),
      create: jest.fn().mockResolvedValue(profile),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const cloudinary = {
      deleteAsset: jest.fn(),
      ...cloudinaryOverrides,
    } as never;
    const service = new PlayersService(model as never, cloudinary);
    return { service, model, cloudinary: cloudinary as CloudinaryService };
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

  it('deletes every Cloudinary media asset before removing the profile (admin delete)', async () => {
    const id = new Types.ObjectId().toString();
    const { service, model, cloudinary } = buildService({
      media: [
        { publicId: 'photo-1', type: MediaType.PHOTO },
        { publicId: 'video-1', type: MediaType.VIDEO },
      ],
    });

    await service.deleteProfileAndMedia(id);

    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('photo-1', 'image');
    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('video-1', 'video');
    expect(model.deleteOne).toHaveBeenCalledWith({ _id: id });
  });

  it('rejects deleting a profile that does not exist', async () => {
    const { service } = buildService(null);

    await expect(
      service.deleteProfileAndMedia(new Types.ObjectId().toString()),
    ).rejects.toThrow(NotFoundException);
  });
});
