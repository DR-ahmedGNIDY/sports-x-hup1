import { PublicCodePrefix, PublicCodesService } from './public-codes.service';

describe('PublicCodesService', () => {
  function buildService(seq: number) {
    const counterModel = {
      findOneAndUpdate: jest.fn().mockResolvedValue({ _id: 'CLB', seq }),
    };
    return {
      service: new PublicCodesService(counterModel as never),
      counterModel,
    };
  }

  it('allocates a zero-padded code from an atomic upserting increment', async () => {
    const { service, counterModel } = buildService(1);

    await expect(service.allocate(PublicCodePrefix.CLUB)).resolves.toBe(
      'CLB-000001',
    );
    expect(counterModel.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: 'CLB' },
      { $inc: { seq: 1 } },
      { upsert: true, new: true },
    );
  });

  it('grows past six digits rather than wrapping or truncating', async () => {
    const { service } = buildService(1_000_000);
    await expect(service.allocate(PublicCodePrefix.PLAYER)).resolves.toBe(
      'PLY-1000000',
    );
  });

  describe('normalize', () => {
    it('accepts the canonical form', () => {
      expect(PublicCodesService.normalize('PLY-000123')).toBe('PLY-000123');
    });

    it('tolerates whitespace and lower case, since codes are typed by hand', () => {
      expect(PublicCodesService.normalize('  ply-000123 ')).toBe('PLY-000123');
    });

    it.each([
      ['', 'empty'],
      ['PLY-123', 'too few digits'],
      ['XXX-000123', 'unknown prefix'],
      ['PLY000123', 'missing separator'],
      ['PLY-00012a', 'non-digits'],
      ['PLY-000123; drop', 'trailing injection-ish payload'],
      ['{"$ne": null}', 'operator-shaped input'],
    ])('rejects %s (%s)', (input) => {
      expect(PublicCodesService.normalize(input)).toBeNull();
    });
  });

  describe('normalizeFor', () => {
    it('rejects a well-formed code of the wrong kind', () => {
      expect(
        PublicCodesService.normalizeFor('CLB-000123', PublicCodePrefix.PLAYER),
      ).toBeNull();
      expect(
        PublicCodesService.normalizeFor('CLB-000123', PublicCodePrefix.CLUB),
      ).toBe('CLB-000123');
    });
  });
});
