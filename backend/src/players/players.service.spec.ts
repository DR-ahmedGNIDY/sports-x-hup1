import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { VideosService } from '../videos/videos.service';
import { PlayersService } from './players.service';
import { MediaType, ProfileVisibility } from './schemas/player-profile.schema';

// A real PNG signature — Phase 0.5 added magic-byte content validation
// (common/file-signature.ts), so mock upload files must carry genuine
// image bytes rather than an arbitrary placeholder buffer.
const PNG_SIGNATURE = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0,
]);

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
      // search()'s pagination chain: find(filter).skip(n).limit(n),
      // resolved separately from countDocuments(filter) via Promise.all.
      find: jest.fn().mockReturnValue({
        skip: jest.fn().mockReturnValue({
          limit: jest.fn().mockResolvedValue([]),
        }),
      }),
      countDocuments: jest.fn().mockResolvedValue(0),
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
    const publicCodes = {
      allocate: jest.fn().mockResolvedValue('PLY-000001'),
    } as never;
    const service = new PlayersService(
      model as never,
      savedPlayerModel as never,
      cloudinary,
      videosService,
      publicCodes,
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

  it('rejects a photo upload larger than the 5MB image size limit', async () => {
    const { service, cloudinary } = buildService({
      media: [],
      save: jest.fn(),
    });

    await expect(
      service.addMedia('user-1', {
        buffer: PNG_SIGNATURE,
        mimetype: 'image/png',
        size: 6 * 1024 * 1024, // over the 5MB IMAGE_SIZE_LIMIT_BYTES cap
      } as Express.Multer.File),
    ).rejects.toThrow(BadRequestException);
    expect(cloudinary.uploadBuffer).not.toHaveBeenCalled();
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
      service.addMedia('user-1', {
        buffer: PNG_SIGNATURE,
        mimetype: 'image/png',
        size: 10,
      } as Express.Multer.File),
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
      service.addMedia('user-1', {
        buffer: PNG_SIGNATURE,
        mimetype: 'image/png',
        size: 10,
      } as Express.Multer.File),
    ).rejects.toThrow('db down');

    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('new-id', 'image');
  });

  describe('setProfilePhoto', () => {
    const file = {
      buffer: PNG_SIGNATURE,
      mimetype: 'image/png',
      size: 10,
    } as Express.Multer.File;

    it('stores the upload in the dedicated profilePhoto field, not media', async () => {
      const profile: {
        media: unknown[];
        profilePhoto?: unknown;
        save: jest.Mock;
      } = { media: [], save: jest.fn() };
      const { service } = buildService(profile);

      const result = await service.setProfilePhoto('user-1', file);

      expect(result.profilePhoto).toEqual({
        publicId: 'new-id',
        secureUrl: 'https://x',
      });
      expect(result.media).toEqual([]);
      expect(profile.save).toHaveBeenCalled();
    });

    it('deletes the previous photo from Cloudinary only after the new one is saved', async () => {
      const profile = {
        media: [],
        profilePhoto: { publicId: 'old-id', secureUrl: 'https://old' },
        save: jest.fn(),
      };
      const { service, cloudinary } = buildService(profile);

      await service.setProfilePhoto('user-1', file);

      expect(cloudinary.deleteAsset).toHaveBeenCalledWith('old-id', 'image');
      const saveOrder = profile.save.mock.invocationCallOrder[0];
      const deleteOrder = (cloudinary.deleteAsset as jest.Mock).mock
        .invocationCallOrder[0];
      expect(saveOrder).toBeLessThan(deleteOrder);
    });

    it('deletes the just-uploaded asset (not the old one) if saving fails', async () => {
      const profile = {
        media: [],
        profilePhoto: { publicId: 'old-id', secureUrl: 'https://old' },
        save: jest.fn().mockRejectedValue(new Error('db down')),
      };
      const { service, cloudinary } = buildService(profile);

      await expect(service.setProfilePhoto('user-1', file)).rejects.toThrow(
        'db down',
      );

      expect(cloudinary.deleteAsset).toHaveBeenCalledWith('new-id', 'image');
      expect(cloudinary.deleteAsset).not.toHaveBeenCalledWith(
        'old-id',
        'image',
      );
    });
  });

  describe('removeProfilePhoto', () => {
    it('rejects when the profile has no photo to remove', async () => {
      const { service } = buildService({ media: [], save: jest.fn() });

      await expect(service.removeProfilePhoto('user-1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('deletes the Cloudinary asset and clears the field', async () => {
      const profile = {
        media: [],
        profilePhoto: { publicId: 'old-id', secureUrl: 'https://old' },
        save: jest.fn(),
      };
      const { service, cloudinary } = buildService(profile);

      const result = await service.removeProfilePhoto('user-1');

      expect(cloudinary.deleteAsset).toHaveBeenCalledWith('old-id', 'image');
      expect(result.profilePhoto).toBeUndefined();
      expect(profile.save).toHaveBeenCalled();
    });
  });

  describe('search', () => {
    it('always scopes to PUBLIC visibility, even with no filters given', async () => {
      const { service, model } = buildService(null);

      await service.search({});

      const filter = model.find.mock.calls[0][0];
      expect(filter).toEqual({ visibility: ProfileVisibility.PUBLIC });
    });

    it('matches the search term against firstName or lastName, case-insensitively', async () => {
      const { service, model } = buildService(null);

      await service.search({ search: 'ahmed' });

      const filter = model.find.mock.calls[0][0];
      expect(filter.$or).toEqual([
        { firstName: { $regex: 'ahmed', $options: 'i' } },
        { lastName: { $regex: 'ahmed', $options: 'i' } },
      ]);
      // The same filter object is reused for the count query.
      expect(model.countDocuments).toHaveBeenCalledWith(filter);
    });

    it('escapes regex metacharacters in the search term instead of treating them as regex syntax', async () => {
      const { service, model } = buildService(null);

      await service.search({ search: 'a.*+(b)' });

      const filter = model.find.mock.calls[0][0];
      expect(filter.$or[0].firstName.$regex).toBe('a\\.\\*\\+\\(b\\)');
    });

    it('ignores a search term that is empty or only whitespace', async () => {
      const { service, model } = buildService(null);

      await service.search({ search: '   ' });

      const filter = model.find.mock.calls[0][0];
      expect(filter.$or).toBeUndefined();
    });

    it('applies sport/country/position/preferredFoot/weight as exact-match filters', async () => {
      const { service, model } = buildService(null);

      await service.search({
        sport: 'Football',
        country: 'EG',
        position: 'GK',
        preferredFoot: 'RIGHT' as never,
        weight: 70,
      });

      const filter = model.find.mock.calls[0][0];
      expect(filter).toMatchObject({
        sport: 'Football',
        country: 'EG',
        position: 'GK',
        preferredFoot: 'RIGHT',
        weight: 70,
      });
    });

    it('translates minHeight/maxHeight into a $gte/$lte range on height', async () => {
      const { service, model } = buildService(null);

      await service.search({ minHeight: 170, maxHeight: 190 });

      const filter = model.find.mock.calls[0][0];
      expect(filter.height).toEqual({ $gte: 170, $lte: 190 });
    });

    it('translates minAge/maxAge into a dateOfBirth range (older minimum age -> earlier/equal date)', async () => {
      const { service, model } = buildService(null);

      await service.search({ minAge: 20, maxAge: 25 });

      const filter = model.find.mock.calls[0][0] as {
        dateOfBirth: { $lte: Date; $gte: Date };
      };
      // minAge=20 excludes anyone younger, i.e. born after (today - 20y).
      expect(filter.dateOfBirth.$lte.getFullYear()).toBe(
        new Date().getFullYear() - 20,
      );
      // maxAge=25 excludes anyone older, i.e. born before (today - 25y).
      expect(filter.dateOfBirth.$gte.getFullYear()).toBe(
        new Date().getFullYear() - 25,
      );
    });

    it('paginates with the fixed server-side page size and returns items/page/pageSize/total', async () => {
      const items = [{ firstName: 'A' }, { firstName: 'B' }];
      const { service, model } = buildService(null);
      const limitMock = jest.fn().mockResolvedValue(items);
      const skipMock = jest.fn().mockReturnValue({ limit: limitMock });
      model.find.mockReturnValue({ skip: skipMock });
      model.countDocuments.mockResolvedValue(37);

      const result = await service.search({ page: 3 });

      expect(skipMock).toHaveBeenCalledWith(40); // (page 3 - 1) * pageSize 20
      expect(limitMock).toHaveBeenCalledWith(20);
      expect(result).toEqual({
        items,
        page: 3,
        pageSize: 20,
        total: 37,
      });
    });
  });

  describe('public code', () => {
    it('allocates a code once and stores it conditionally', async () => {
      const profile = { _id: 'p1', publicCode: undefined };
      const { service, model } = buildService(profile);
      model.findOneAndUpdate.mockResolvedValue({
        ...profile,
        publicCode: 'PLY-000001',
      });

      const result = await service.ensurePublicCode(profile as never);

      const [filter, update] = model.findOneAndUpdate.mock.calls[0];
      expect(filter).toEqual({
        _id: 'p1',
        publicCode: { $in: [null, undefined] },
      });
      expect(update).toEqual({ $set: { publicCode: 'PLY-000001' } });
      expect(result.publicCode).toBe('PLY-000001');
    });

    it('never rewrites a code a profile already published', async () => {
      const profile = { _id: 'p1', publicCode: 'PLY-000042' };
      const { service, model } = buildService(profile);

      await service.ensurePublicCode(profile as never);

      expect(model.findOneAndUpdate).not.toHaveBeenCalled();
    });

    it('finds a public player by code', async () => {
      const { service, model } = buildService({
        visibility: ProfileVisibility.PUBLIC,
      });

      await expect(
        service.findPublicByCodeOrThrow('ply-000001'),
      ).resolves.toBeTruthy();
      // Normalized before the query, and matched on the indexed field.
      expect(model.findOne).toHaveBeenCalledWith({ publicCode: 'PLY-000001' });
    });

    it('does not let a code bypass a private profile', async () => {
      const { service } = buildService({
        visibility: ProfileVisibility.PRIVATE,
      });

      await expect(
        service.findPublicByCodeOrThrow('PLY-000001'),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects a club code, and a malformed one, without touching the database', async () => {
      const { service, model } = buildService({
        visibility: ProfileVisibility.PUBLIC,
      });

      await expect(
        service.findPublicByCodeOrThrow('CLB-000001'),
      ).rejects.toThrow(NotFoundException);
      await expect(service.findPublicByCodeOrThrow('nonsense')).rejects.toThrow(
        NotFoundException,
      );
      expect(model.findOne).not.toHaveBeenCalled();
    });
  });
});
