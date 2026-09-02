import { NotFoundException } from '@nestjs/common';
import { ClubsService } from './clubs.service';

describe('ClubsService', () => {
  function buildService(profile: Record<string, unknown> | null) {
    const model = {
      findOne: jest.fn().mockResolvedValue(profile),
      findById: jest.fn().mockResolvedValue(profile),
      findOneAndUpdate: jest.fn().mockResolvedValue(profile),
      create: jest.fn().mockResolvedValue(profile),
      // findAllPublic's chain: find(filter).sort().skip().limit(), with
      // countDocuments resolved alongside it.
      find: jest.fn().mockReturnValue({
        sort: jest.fn().mockReturnValue({
          skip: jest.fn().mockReturnValue({
            limit: jest.fn().mockResolvedValue([]),
          }),
        }),
      }),
      countDocuments: jest.fn().mockResolvedValue(0),
    };
    const cloudinary = { deleteAsset: jest.fn(), uploadBuffer: jest.fn() };
    const publicCodes = {
      allocate: jest.fn().mockResolvedValue('CLB-000001'),
    };
    const service = new ClubsService(
      model as never,
      cloudinary as never,
      publicCodes as never,
    );
    return { service, model, publicCodes };
  }

  describe('public code', () => {
    it('allocates a code once and stores it conditionally', async () => {
      const profile = { _id: 'c1', publicCode: undefined };
      const { service, model } = buildService(profile);
      model.findOneAndUpdate.mockResolvedValue({
        ...profile,
        publicCode: 'CLB-000001',
      });

      const result = await service.ensurePublicCode(profile as never);

      const [filter, update] = model.findOneAndUpdate.mock.calls[0];
      expect(filter).toEqual({
        _id: 'c1',
        publicCode: { $in: [null, undefined] },
      });
      expect(update).toEqual({ $set: { publicCode: 'CLB-000001' } });
      expect(result.publicCode).toBe('CLB-000001');
    });

    it('keeps the winner’s code when two requests race', async () => {
      const profile = { _id: 'c1', publicCode: undefined };
      const { service, model } = buildService(profile);
      // The conditional update matched nothing — someone else got there
      // first — so the loser re-reads rather than overwriting.
      model.findOneAndUpdate.mockResolvedValue(null);
      model.findById.mockResolvedValue({ _id: 'c1', publicCode: 'CLB-000007' });

      const result = await service.ensurePublicCode(profile as never);

      expect(result.publicCode).toBe('CLB-000007');
    });

    it('never rewrites a code a profile already published', async () => {
      const profile = { _id: 'c1', publicCode: 'CLB-000042' };
      const { service, model, publicCodes } = buildService(profile);

      await service.ensurePublicCode(profile as never);

      expect(publicCodes.allocate).not.toHaveBeenCalled();
      expect(model.findOneAndUpdate).not.toHaveBeenCalled();
    });

    it('finds a club by code, normalizing what the user typed', async () => {
      const { service, model } = buildService({ _id: 'c1' });

      await expect(
        service.findByPublicCodeOrThrow(' clb-000001 '),
      ).resolves.toBeTruthy();
      expect(model.findOne).toHaveBeenCalledWith({ publicCode: 'CLB-000001' });
    });

    it('answers 404 for an unknown code', async () => {
      const { service } = buildService(null);

      await expect(
        service.findByPublicCodeOrThrow('CLB-000999'),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects a player code, and a malformed one, without touching the database', async () => {
      const { service, model } = buildService({ _id: 'c1' });

      await expect(
        service.findByPublicCodeOrThrow('PLY-000001'),
      ).rejects.toThrow(NotFoundException);
      await expect(
        service.findByPublicCodeOrThrow('../../etc'),
      ).rejects.toThrow(NotFoundException);
      expect(model.findOne).not.toHaveBeenCalled();
    });
  });

  describe('findAllPublic search', () => {
    it('matches the name case-insensitively', async () => {
      const { service, model } = buildService(null);

      await service.findAllPublic(1, undefined, 'ahly');

      const [filter] = model.find.mock.calls[0];
      expect(filter.name['$regex']).toBe('ahly');
      expect(filter.name['$options']).toBe('i');
    });

    it('escapes regex syntax so a name is text, not a pattern', async () => {
      const { service, model } = buildService(null);

      // Unescaped, '(' throws at query time and '.*' would match anything.
      await service.findAllPublic(1, undefined, 'a.*(');

      const [filter] = model.find.mock.calls[0];
      expect(filter.name['$regex']).toBe(String.raw`a\.\*\(`);
    });

    it('ignores a blank search rather than matching everything', async () => {
      const { service, model } = buildService(null);

      await service.findAllPublic(1, undefined, '   ');

      const [filter] = model.find.mock.calls[0];
      expect(filter.name).toBeUndefined();
    });

    it('combines with the country filter', async () => {
      const { service, model } = buildService(null);

      await service.findAllPublic(1, 'Egypt', 'ahly');

      const [filter] = model.find.mock.calls[0];
      expect(filter.country).toBe('Egypt');
      expect(filter.name).toBeDefined();
    });

    it('counts the same filter it pages over', async () => {
      const { service, model } = buildService(null);

      await service.findAllPublic(2, undefined, 'ahly');

      expect(model.countDocuments.mock.calls[0][0]).toEqual(
        model.find.mock.calls[0][0],
      );
    });
  });
});
