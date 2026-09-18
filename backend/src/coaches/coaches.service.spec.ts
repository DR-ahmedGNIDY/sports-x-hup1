import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { ProfileVisibility } from '../players/schemas/player-profile.schema';
import { CoachesService } from './coaches.service';

describe('CoachesService', () => {
  function profileDoc(overrides: Record<string, unknown> = {}) {
    const doc: Record<string, unknown> = {
      _id: new Types.ObjectId(),
      userId: new Types.ObjectId(),
      publicCode: 'COA-000001',
      contact: {},
      certifications: [],
      experience: [],
      achievements: [],
      socialLinks: [],
      media: [],
      visibility: ProfileVisibility.PUBLIC,
      save: jest.fn().mockResolvedValue(undefined),
      set: jest.fn(function (this: Record<string, unknown>, k, v) {
        this[k as string] = v;
      }),
      ...overrides,
    };
    return doc;
  }

  function build(profile: Record<string, unknown> | null) {
    const model = {
      findOneAndUpdate: jest.fn().mockResolvedValue(profile),
      findOne: jest.fn().mockResolvedValue(profile),
      findById: jest.fn().mockResolvedValue(profile),
    };
    const cloudinary = {
      uploadBuffer: jest.fn(),
      deleteAsset: jest.fn(),
    };
    const publicCodes = { allocate: jest.fn().mockResolvedValue('COA-000002') };
    const service = new CoachesService(
      model as never,
      cloudinary as never,
      publicCodes as never,
    );
    return { service, model, cloudinary, publicCodes };
  }

  it('allocates a COA- code for a new coach profile', async () => {
    const fresh = profileDoc({ publicCode: undefined });
    const { service, publicCodes } = build(fresh);

    await service.getOrCreateForUser('user-1');

    expect(publicCodes.allocate).toHaveBeenCalledWith('COA');
  });

  it('merges contact details instead of replacing them', async () => {
    const profile = profileDoc({ contact: { phone: '1', email: 'a@b.co' } });
    const { service } = build(profile);

    await service.updateProfile('user-1', {
      headline: 'Head coach',
      contact: { whatsapp: '2' },
    });

    expect(profile.contact).toEqual({
      phone: '1',
      email: 'a@b.co',
      whatsapp: '2',
    });
    expect(profile.headline).toBe('Head coach');
  });

  it('adds, edits and removes a CV entry', async () => {
    const profile = profileDoc();
    const { service } = build(profile);

    await service.addEntry('user-1', 'certifications', { name: 'CAF C' });
    const entries = profile.certifications as { _id?: Types.ObjectId }[];
    expect(entries).toHaveLength(1);

    const id = new Types.ObjectId();
    entries[0]._id = id;
    await service.updateEntry('user-1', 'certifications', id.toString(), {
      year: 2020,
    });
    expect(entries[0]).toMatchObject({ name: 'CAF C', year: 2020 });

    await service.removeEntry('user-1', 'certifications', id.toString());
    expect(profile.certifications).toEqual([]);
  });

  it('caps a CV section at 30 entries', async () => {
    const profile = profileDoc({
      experience: Array.from({ length: 30 }, () => ({})),
    });
    const { service } = build(profile);

    await expect(
      service.addEntry('user-1', 'experience', {
        clubName: 'X',
        role: 'Y',
        startYear: 2020,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('answers 404 for an unknown CV entry', async () => {
    const { service } = build(profileDoc());
    await expect(
      service.removeEntry(
        'user-1',
        'experience',
        new Types.ObjectId().toString(),
      ),
    ).rejects.toThrow('Experience entry not found.');
  });

  it('hides a private coach from a code lookup', async () => {
    const { service } = build(
      profileDoc({ visibility: ProfileVisibility.PRIVATE }),
    );
    await expect(service.findPublicByCodeOrThrow('COA-000001')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('refuses a player code at the coach lookup without a query', async () => {
    const { service, model } = build(profileDoc());
    await expect(service.findPublicByCodeOrThrow('PLY-000001')).rejects.toThrow(
      NotFoundException,
    );
    expect(model.findOne).not.toHaveBeenCalled();
  });

  it('deletes media and photo assets with the profile', async () => {
    const profile = profileDoc({
      media: [{ publicId: 'v1', type: 'VIDEO' }],
      profilePhoto: { publicId: 'p1', secureUrl: 'x' },
    });
    const { service, model, cloudinary } = build(profile);
    (model as Record<string, unknown>).deleteOne = jest.fn();

    await service.deleteProfileAndMediaByUserId('user-1');

    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('v1', 'video');
    expect(cloudinary.deleteAsset).toHaveBeenCalledWith('p1', 'image');
  });
});
