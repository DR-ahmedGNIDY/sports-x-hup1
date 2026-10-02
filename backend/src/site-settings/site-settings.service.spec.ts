import { SiteSettingsService } from './site-settings.service';

describe('SiteSettingsService', () => {
  function buildService(doc: Record<string, unknown> | null = null) {
    const model = {
      findOne: jest
        .fn()
        .mockReturnValue({ exec: jest.fn().mockResolvedValue(doc) }),
      findOneAndUpdate: jest
        .fn()
        .mockReturnValue({ exec: jest.fn().mockResolvedValue(doc) }),
    };
    return { service: new SiteSettingsService(model as never), model };
  }

  it('returns empty defaults before anything was saved', async () => {
    const { service } = buildService(null);

    const view = await service.get();

    expect(view.facebookUrl).toBe('');
    expect(view.phones).toEqual([]);
    expect(view.updatedAt).toBeNull();
  });

  it('upserts the singleton and only sets the fields that were sent', async () => {
    const { service, model } = buildService({
      facebookUrl: 'https://fb.com/sxh',
    });

    await service.update({
      facebookUrl: 'https://fb.com/sxh',
      email: undefined,
    });

    const [filter, update, options] = model.findOneAndUpdate.mock.calls[0];
    expect(filter).toEqual({ key: 'main' });
    expect(update).toEqual({ $set: { facebookUrl: 'https://fb.com/sxh' } });
    expect(options).toMatchObject({ upsert: true });
  });

  it('stores an empty label for a phone sent without one', async () => {
    const { service, model } = buildService({});

    await service.update({ phones: [{ number: '+201000000000' }] });

    const [, update] = model.findOneAndUpdate.mock.calls[0];
    expect(update.$set.phones).toEqual([
      { label: '', number: '+201000000000' },
    ]);
  });
});
