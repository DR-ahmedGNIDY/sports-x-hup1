import { BadRequestException, NotFoundException } from '@nestjs/common';
import { BannersService } from './banners.service';
import { BannerSlot } from './banner-slot';

describe('BannersService', () => {
  function buildService(banner: Record<string, unknown> | null = null) {
    const found = {
      sort: jest.fn(),
    };
    found.sort.mockReturnValue({ exec: jest.fn().mockResolvedValue([]) });

    const model = {
      find: jest.fn().mockReturnValue(found),
      findById: jest.fn().mockResolvedValue(banner),
      create: jest.fn().mockImplementation((doc) => Promise.resolve(doc)),
    };
    const images = {
      upload: jest.fn().mockResolvedValue({
        publicId: 'new-1',
        secureUrl: 'https://img/new.jpg',
      }),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    return {
      service: new BannersService(model as never, images as never),
      model,
      images,
      found,
    };
  }

  function banner(overrides: Record<string, unknown> = {}) {
    const doc = {
      _id: { toString: () => 'b1' },
      desktopImage: { publicId: 'old-desktop', secureUrl: 'https://img/d.jpg' },
      mobileImage: undefined as unknown,
      isActive: true,
      save: jest.fn(),
      ...overrides,
    };
    doc.save = jest.fn().mockResolvedValue(doc);
    return doc;
  }

  describe('publishing', () => {
    it('withholds a banner that has no desktop image', async () => {
      const { service, model } = buildService();

      await service.listPublished();

      // Created but never finished. An empty slide in a rotation reads as
      // the page being broken, so it stays out of the hero.
      expect(model.find).toHaveBeenCalledWith({
        isActive: true,
        'desktopImage.secureUrl': { $exists: true },
      });
    });

    it('shows the merchant everything, including the unfinished ones', async () => {
      const { service, model } = buildService();
      await service.listAll();
      // No filter at all — that is how the dashboard can explain why a
      // banner is missing from the storefront.
      expect(model.find).toHaveBeenCalledWith();
    });

    it('orders by the merchant’s own sort, not by creation', async () => {
      const { service, found } = buildService();
      await service.listPublished();
      expect(found.sort).toHaveBeenCalledWith({ sortOrder: 1, _id: 1 });
    });
  });

  describe('images', () => {
    it('saves the new image before deleting the one it replaced', async () => {
      const doc = banner();
      const { service, model, images } = buildService(doc);
      model.findById.mockResolvedValue(doc);

      const order: string[] = [];
      doc.save.mockImplementation(() => {
        order.push('save');
        return Promise.resolve(doc);
      });
      images.remove.mockImplementation(() => {
        order.push('remove');
        return Promise.resolve();
      });

      await service.setImage('b1', BannerSlot.DESKTOP, {} as never);

      // An orphan in Cloudinary costs storage; deleting first and then
      // failing to save would leave the hero pointing at nothing.
      expect(order).toEqual(['save', 'remove']);
      expect(images.remove).toHaveBeenCalledWith('old-desktop');
      expect(doc.desktopImage).toEqual({
        publicId: 'new-1',
        secureUrl: 'https://img/new.jpg',
      });
    });

    it('writes the mobile image without touching the desktop one', async () => {
      const doc = banner();
      const { service, model, images } = buildService(doc);
      model.findById.mockResolvedValue(doc);

      await service.setImage('b1', BannerSlot.MOBILE, {} as never);

      expect(doc.mobileImage).toEqual({
        publicId: 'new-1',
        secureUrl: 'https://img/new.jpg',
      });
      expect(doc.desktopImage).toEqual({
        publicId: 'old-desktop',
        secureUrl: 'https://img/d.jpg',
      });
      // Nothing to replace on an empty slot, so nothing is deleted.
      expect(images.remove).not.toHaveBeenCalled();
    });

    it('refuses to clear the desktop image', async () => {
      const { service } = buildService(banner());

      // Removing it would silently unlist the banner rather than doing
      // what was asked.
      await expect(
        service.removeImage('b1', BannerSlot.DESKTOP),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('clears the mobile image and its asset', async () => {
      const doc = banner({
        mobileImage: { publicId: 'old-mobile', secureUrl: 'https://img/m.jpg' },
      });
      const { service, model, images } = buildService(doc);
      model.findById.mockResolvedValue(doc);

      await service.removeImage('b1', BannerSlot.MOBILE);

      expect(doc.mobileImage).toBeUndefined();
      expect(images.remove).toHaveBeenCalledWith('old-mobile');
    });

    it('is a no-op when there is no mobile image to clear', async () => {
      const doc = banner();
      const { service, model, images } = buildService(doc);
      model.findById.mockResolvedValue(doc);

      await service.removeImage('b1', BannerSlot.MOBILE);

      expect(doc.save).not.toHaveBeenCalled();
      expect(images.remove).not.toHaveBeenCalled();
    });

    it('reports a missing banner rather than uploading into nowhere', async () => {
      const { service, images } = buildService(null);

      await expect(
        service.setImage('gone', BannerSlot.DESKTOP, {} as never),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(images.upload).not.toHaveBeenCalled();
    });
  });

  describe('writing', () => {
    it('creates a banner with no images, ready to be filled', async () => {
      const { service, model } = buildService();

      await service.create({});

      // The images are multipart and need the banner's id to name their
      // Cloudinary folder, so they arrive after this.
      const created = model.create.mock.calls[0][0] as Record<string, unknown>;
      expect(created.isActive).toBe(true);
      expect(created.sortOrder).toBe(0);
      expect(created).not.toHaveProperty('desktopImage');
    });

    it('deactivates rather than deleting', async () => {
      const doc = banner();
      const { service, model } = buildService(doc);
      model.findById.mockResolvedValue(doc);

      await service.deactivate('b1');

      expect(doc.isActive).toBe(false);
      expect(doc.save).toHaveBeenCalled();
    });
  });
});
