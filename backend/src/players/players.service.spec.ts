import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { VideosService } from '../videos/videos.service';
import { PlayersService } from './players.service';
import { MediaType, ProfileVisibility } from './schemas/player-profile.schema';

describe('PlayersService', () => {
  function buildService(
    profile: Record<string, unknown> | null,
    cloudinaryOverrides: Partial<CloudinaryService> = {},
    savedByClubsCount = 0,
    videosServiceOverrides: Partial<VideosService> = {},
  ) {
    const model = {
      findById: jest.fn().mockResolvedValue(profile),
      findOne: jest.fn().mockResolvedValue(profile),
      findOneAndUpdate: jest.fn().mockResolvedValue(profile),
      create: jest.fn().mockResolvedValue(profile),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const savedPlayerModel = {
      countDocuments: jest.fn().mockResolvedValue(savedByClubsCount),
    };
    const cloudinary = {
      deleteAsset: jest.fn(),
      uploadBuffer: jest
        .fn()
        .mockResolvedValue({ publicId: 'new-id', secureUrl: 'https://x' }),
      ...cloudinaryOverrides,
    } as never;
    const videosService = {
      deleteAllForPlayer: jest.fn(),
      ...videosServiceOverrides,
    } as never;
    const service = new PlayersService(
      model as never,
      savedPlayerModel as never,
      cloudinary,
      videosService,
    );
    return {
      service,
      model,
      savedPlayerModel,
      cloudinary: cloudinary as CloudinaryService,
      videosService: videosService as VideosService,
    };
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

  it('cascade-deletes the player videos/likes/comments when the profile is deleted', async () => {
    const id = new Types.ObjectId().toString();
    const { service, videosService } = buildService({ media: [] });

    await service.deleteProfileAndMedia(id);

    expect(videosService.deleteAllForPlayer).toHaveBeenCalledWith(id);
  });

  it('rejects deleting a profile that does not exist', async () => {
    const { service } = buildService(null);

    await expect(
      service.deleteProfileAndMedia(new Types.ObjectId().toString()),
    ).rejects.toThrow(NotFoundException);
  });

  it('creates a missing profile via an atomic upsert, not findOne-then-create', async () => {
    // Regression test: GET /players/me and GET /players/me/stats both call
    // getOrCreateForUser and can land concurrently for a brand-new player.
    // A separate findOne + create lets both see "not found" and both try
    // to insert, and the loser dies on the unique userId index. The fix
    // is one atomic findOneAndUpdate — assert that's actually what's used.
    const profile = { userId: 'user-1' };
    const { service, model } = buildService(profile);

    const result = await service.getOrCreateForUser('user-1');

    expect(model.findOneAndUpdate).toHaveBeenCalledWith(
      { userId: 'user-1' },
      { $setOnInsert: { userId: 'user-1' } },
      { new: true, upsert: true },
    );
    expect(model.findOne).not.toHaveBeenCalled();
    expect(model.create).not.toHaveBeenCalled();
    expect(result).toBe(profile);
  });

  it('counts saved-by-clubs against the profile id, not the user id', async () => {
    const profileId = new Types.ObjectId();
    const { service, savedPlayerModel } = buildService(
      { _id: profileId },
      {},
      3,
    );

    const result = await service.getStatsForUser('some-user-id');

    expect(savedPlayerModel.countDocuments).toHaveBeenCalledWith({
      playerId: profileId,
    });
    expect(result.savedByClubsCount).toBe(3);
  });

  it('rejects adding an achievement once the profile already has 30', async () => {
    const achievements = Array.from({ length: 30 }, (_, i) => ({
      _id: new Types.ObjectId(),
      title: `Achievement ${i}`,
      year: 2000,
    }));
    const { service } = buildService({
      achievements,
      save: jest.fn(),
    });

    await expect(
      service.addAchievement('user-1', { title: 'One too many', year: 2020 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects adding a social link once the profile already has 30', async () => {
    const socialLinks = Array.from({ length: 30 }, () => ({
      _id: new Types.ObjectId(),
      platform: 'x',
      url: 'https://x.com',
    }));
    const { service } = buildService({
      socialLinks,
      save: jest.fn(),
    });

    await expect(
      service.addSocialLink('user-1', {
        platform: 'one-too-many',
        url: 'https://example.com',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects adding media once the profile already has 30 items', async () => {
    const media = Array.from({ length: 30 }, () => ({
      publicId: 'p',
      type: MediaType.PHOTO,
    }));
    const { service, cloudinary } = buildService({
      media,
      save: jest.fn(),
    });

    await expect(
      service.addMedia(
        'user-1',
        {
          buffer: Buffer.from('x'),
          mimetype: 'image/png',
          size: 10,
        } as Express.Multer.File,
        false,
      ),
    ).rejects.toThrow(BadRequestException);
    // Rejected before ever uploading to Cloudinary.
    expect(cloudinary.uploadBuffer).not.toHaveBeenCalled();
  });

  it('deletes the just-uploaded Cloudinary asset if saving the new media fails', async () => {
    const profile: { media: unknown[]; save: jest.Mock } = {
      media: [],
      save: jest.fn().mockRejectedValue(new Error('db down')),
    };
    const { service, cloudinary } = buildService(profile);

    await expect(
      service.addMedia(
        'user-1',
        {
          buffer: Buffer.from('x'),
          mimetype: 'image/png',
          size: 10,
        } as Express.Multer.File,
        false,
      ),
    ).rejects.toThrow('db down');

    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('new-id', 'image');
  });
});
