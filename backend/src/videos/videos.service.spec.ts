import { BadRequestException } from '@nestjs/common';
import { Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { SportsService } from '../sports/sports.service';
import { VideosService } from './videos.service';
import { VideoVisibility } from './schemas/video.schema';

describe('VideosService', () => {
  function buildService(options: {
    profile?: Record<string, unknown> | null;
    createResult?: Record<string, unknown>;
    createError?: unknown;
    cloudinaryOverrides?: Partial<CloudinaryService>;
    sportsServiceOverrides?: Partial<SportsService>;
  }) {
    const {
      profile = { _id: new Types.ObjectId(), sport: 'Football' },
      createResult = {
        _id: new Types.ObjectId(),
        playerId: new Types.ObjectId(),
        sport: 'Football',
        category: 'dribbling',
        secureUrl: 'https://x',
        visibility: VideoVisibility.PUBLIC,
        likeCount: 0,
        commentCount: 0,
      },
      createError,
      cloudinaryOverrides = {},
      sportsServiceOverrides = {},
    } = options;

    const videoModel = {
      find: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      create: createError
        ? jest.fn().mockRejectedValue(createError)
        : jest.fn().mockResolvedValue(createResult),
      deleteMany: jest.fn().mockResolvedValue({ deletedCount: 0 }),
      updateOne: jest.fn().mockResolvedValue({}),
    };
    const videoLikeModel = {
      find: jest.fn().mockResolvedValue([]),
      deleteMany: jest.fn().mockResolvedValue({ deletedCount: 0 }),
    };
    const videoCommentModel = {
      find: jest.fn().mockReturnValue({
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([]),
      }),
      deleteMany: jest.fn().mockResolvedValue({ deletedCount: 0 }),
    };
    const playerProfileModel = {
      findOne: jest.fn().mockResolvedValue(profile),
      find: jest.fn().mockResolvedValue([]),
    };
    const clubProfileModel = {
      find: jest.fn().mockResolvedValue([]),
    };
    const userModel = {
      find: jest.fn().mockResolvedValue([]),
    };
    const cloudinary = {
      uploadBuffer: jest
        .fn()
        .mockResolvedValue({ publicId: 'video-1', secureUrl: 'https://x' }),
      deleteAsset: jest.fn(),
      ...cloudinaryOverrides,
    } as never;
    const sportsService = {
      assertSportExists: jest.fn(),
      assertCategoryExists: jest.fn(),
      ...sportsServiceOverrides,
    } as never;

    const service = new VideosService(
      videoModel as never,
      videoLikeModel as never,
      videoCommentModel as never,
      playerProfileModel as never,
      clubProfileModel as never,
      userModel as never,
      cloudinary,
      sportsService,
    );

    return {
      service,
      videoModel,
      videoLikeModel,
      videoCommentModel,
      playerProfileModel,
      clubProfileModel,
      userModel,
      cloudinary: cloudinary as CloudinaryService,
      sportsService: sportsService as SportsService,
    };
  }

  const validFile = {
    buffer: Buffer.from('x'),
    mimetype: 'video/mp4',
    size: 10,
  } as Express.Multer.File;

  it('rejects a non-video mimetype before touching Cloudinary', async () => {
    const { service, cloudinary } = buildService({});

    await expect(
      service.uploadVideo(
        'user-1',
        { category: 'dribbling', visibility: VideoVisibility.PUBLIC },
        { ...validFile, mimetype: 'image/png' },
      ),
    ).rejects.toThrow(BadRequestException);
    expect(cloudinary.uploadBuffer).not.toHaveBeenCalled();
  });

  it('rejects uploading when the player has not set a sport yet', async () => {
    const { service, cloudinary } = buildService({
      profile: { _id: new Types.ObjectId(), sport: undefined },
    });

    await expect(
      service.uploadVideo(
        'user-1',
        { category: 'dribbling', visibility: VideoVisibility.PUBLIC },
        validFile,
      ),
    ).rejects.toThrow(BadRequestException);
    expect(cloudinary.uploadBuffer).not.toHaveBeenCalled();
  });

  it('validates the chosen category against the player sport before uploading', async () => {
    const { service, sportsService } = buildService({});

    await service.uploadVideo(
      'user-1',
      { category: 'dribbling', visibility: VideoVisibility.PUBLIC },
      validFile,
    );

    expect(sportsService.assertCategoryExists).toHaveBeenCalledWith(
      'Football',
      'dribbling',
    );
  });

  it('deletes the just-uploaded Cloudinary asset if the DB write fails', async () => {
    const { service, cloudinary } = buildService({
      createError: new Error('db down'),
    });

    await expect(
      service.uploadVideo(
        'user-1',
        { category: 'dribbling', visibility: VideoVisibility.PUBLIC },
        validFile,
      ),
    ).rejects.toThrow('db down');

    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('video-1', 'video');
  });

  it('rejects an unknown sport in the Community feed instead of returning an empty page', async () => {
    const { service, sportsService } = buildService({});
    (sportsService.assertSportExists as jest.Mock).mockRejectedValue(
      new BadRequestException('Unknown sport "Curling".'),
    );

    await expect(
      service.communityFeed('Curling', undefined, 1),
    ).rejects.toThrow(BadRequestException);
  });

  it('resolves comment authors with one batched query per model, not one per comment', async () => {
    const videoId = new Types.ObjectId();
    const authorAId = new Types.ObjectId();
    const authorBId = new Types.ObjectId();
    const { service, videoModel, videoCommentModel, userModel, playerProfileModel } =
      buildService({});
    videoModel.findById = jest
      .fn()
      .mockResolvedValue({ _id: videoId, visibility: VideoVisibility.PUBLIC, userId: 'someone' });
    const comments = [
      { _id: new Types.ObjectId(), userId: authorAId, text: 'a' },
      { _id: new Types.ObjectId(), userId: authorBId, text: 'b' },
      { _id: new Types.ObjectId(), userId: authorAId, text: 'c' },
    ];
    videoCommentModel.find = jest.fn().mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      skip: jest.fn().mockReturnThis(),
      limit: jest.fn().mockResolvedValue(comments),
    });
    userModel.find = jest.fn().mockResolvedValue([
      { _id: authorAId, role: 'PLAYER', email: 'a@x.com' },
      { _id: authorBId, role: 'PLAYER', email: 'b@x.com' },
    ]);
    playerProfileModel.find = jest.fn().mockResolvedValue([]);

    await service.listComments('viewer', videoId.toString(), 1);

    // One find() for all distinct authors, not one per comment (3 comments,
    // 2 distinct authors) — this is the N+1 fix.
    expect(userModel.find).toHaveBeenCalledTimes(1);
    expect(playerProfileModel.find).toHaveBeenCalledTimes(1);
  });

  it('cascade-deletes a player video plus its Cloudinary asset, likes and comments', async () => {
    const playerId = new Types.ObjectId().toString();
    const videoId = new Types.ObjectId();
    const { service, videoModel, videoLikeModel, videoCommentModel, cloudinary } =
      buildService({});
    videoModel.find = jest
      .fn()
      .mockResolvedValue([{ _id: videoId, publicId: 'video-1' }]);

    await service.deleteAllForPlayer(playerId);

    // `Video.playerId` is stored as a real ObjectId — the cascade must
    // cast the string id back to one, or (as it silently did before this
    // fix) it deletes nothing.
    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('video-1', 'video');
    expect(videoModel.deleteMany).toHaveBeenCalledWith({
      playerId: new Types.ObjectId(playerId),
    });
    expect(videoLikeModel.deleteMany).toHaveBeenCalledWith({
      videoId: { $in: [videoId] },
    });
    expect(videoCommentModel.deleteMany).toHaveBeenCalledWith({
      videoId: { $in: [videoId] },
    });
  });
});
