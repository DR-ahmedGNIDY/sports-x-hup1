import { BadRequestException, NotFoundException } from '@nestjs/common';
import { slugify } from '../slug';
import { ProductSort } from './dto/list-products.dto';
import { StoreProductsService } from './products.service';

describe('StoreProductsService', () => {
  function buildService() {
    const found = { sort: jest.fn(), skip: jest.fn(), limit: jest.fn() };
    // list()'s chain: find(filter).sort().skip().limit().exec()
    found.sort.mockReturnValue(found);
    found.skip.mockReturnValue(found);
    found.limit.mockReturnValue({ exec: jest.fn().mockResolvedValue([]) });

    const model = {
      find: jest.fn().mockReturnValue(found),
      findOne: jest.fn().mockResolvedValue(null),
      findById: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation((doc) => Promise.resolve(doc)),
      exists: jest.fn().mockResolvedValue(null),
      countDocuments: jest
        .fn()
        .mockReturnValue({ exec: jest.fn().mockResolvedValue(0) }),
    };
    const categories = {
      existsById: jest.fn().mockResolvedValue(true),
      findBySlugOrThrow: jest.fn(),
    };
    const images = {
      upload: jest
        .fn()
        .mockResolvedValue({ publicId: 'cl-1', secureUrl: 'https://img/1.jpg' }),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    const service = new StoreProductsService(
      model as never,
      categories as never,
      images as never,
    );
    return { service, model, categories, images, found };
  }

  // The filter object handed to Mongo is the whole behaviour of the listing
  // endpoint, so the tests assert on it directly.
  function filterFrom(model: { find: jest.Mock }) {
    return model.find.mock.calls[0][0] as Record<string, unknown>;
  }

  describe('listing', () => {
    it('hides inactive products from the storefront but not the admin', async () => {
      const shop = buildService();
      await shop.service.list({});
      expect(filterFrom(shop.model).isActive).toBe(true);

      const admin = buildService();
      await admin.service.list({}, true);
      expect(filterFrom(admin.model)).not.toHaveProperty('isActive');
    });

    it('matches size and colour on the same variant, not across two', async () => {
      const { service, model } = buildService();

      await service.list({ size: 'L', colour: 'black' });

      // The bug this guards against: a product stocking L in white and M in
      // black is not a product stocking black in L, but two dotted paths
      // (`variants.size`/`variants.colour`) would return it.
      expect(filterFrom(model).variants).toEqual({
        $elemMatch: { size: 'L', colour: 'black' },
      });
    });

    it('resolves a category slug rather than requiring its id', async () => {
      const { service, model, categories } = buildService();
      categories.findBySlugOrThrow.mockResolvedValue({ _id: 'cat-1' });

      await service.list({ categorySlug: 'men-tops' });

      expect(categories.findBySlugOrThrow).toHaveBeenCalledWith('men-tops');
      expect(filterFrom(model).categoryId).toBe('cat-1');
    });

    it('rejects an inverted price range instead of returning nothing', async () => {
      const { service } = buildService();
      await expect(
        service.list({ minPriceMinor: 90000, maxPriceMinor: 10000 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('breaks price-sort ties on _id so paging cannot repeat a product', async () => {
      const { service, found } = buildService();
      await service.list({ sort: ProductSort.PRICE_ASC });
      expect(found.sort).toHaveBeenCalledWith({ priceMinor: 1, _id: 1 });
    });
  });

  describe('writing', () => {
    it('refuses a compare-at price that is not above the real price', async () => {
      const { service } = buildService();
      // Otherwise the card advertises a markup as if it were a discount.
      await expect(
        service.create({
          title: { en: 'Cargo Shorts' },
          categoryId: '507f1f77bcf86cd799439011',
          priceMinor: 74000,
          compareAtPriceMinor: 74000,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuses a product pointed at a category that does not exist', async () => {
      const { service, categories } = buildService();
      categories.existsById.mockResolvedValue(false);

      await expect(
        service.create({
          title: { en: 'Cargo Shorts' },
          categoryId: '507f1f77bcf86cd799439011',
          priceMinor: 74000,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('suffixes a slug already taken rather than rejecting the title', async () => {
      const { service, model } = buildService();
      // "black-cargo-shorts" exists; the next season's version still needs
      // to be creatable under the same name.
      model.exists.mockResolvedValueOnce({ _id: 'p1' }).mockResolvedValue(null);

      const created = (await service.create({
        title: { en: 'Black Cargo Shorts' },
        categoryId: '507f1f77bcf86cd799439011',
        priceMinor: 74000,
      })) as unknown as { slug: string };

      expect(created.slug).toBe('black-cargo-shorts-2');
    });

    it('unlists rather than deletes, so past orders still resolve', async () => {
      const { service, model } = buildService();
      const product = { isActive: true, save: jest.fn() };
      product.save.mockResolvedValue(product);
      model.findById.mockResolvedValue(product);

      await service.deactivate('p1');

      expect(product.isActive).toBe(false);
      expect(product.save).toHaveBeenCalled();
    });
  });

  describe('images', () => {
    function productWithImages(count: number) {
      const product = {
        _id: { toString: () => 'p1' },
        images: Array.from({ length: count }, (_, i) => ({
          publicId: `cl-${i}`,
          secureUrl: `https://img/${i}.jpg`,
        })),
        save: jest.fn(),
      };
      product.save.mockResolvedValue(product);
      return product;
    }

    it('appends rather than replacing, so the gallery keeps its order', async () => {
      const { service, model, images } = buildService();
      const product = productWithImages(1);
      model.findById.mockResolvedValue(product);

      await service.addImage('p1', {} as never);

      expect(images.upload).toHaveBeenCalledTimes(1);
      expect(product.images).toHaveLength(2);
      // The first image is the one every tile renders, so an upload must
      // never displace it.
      expect(product.images[0].publicId).toBe('cl-0');
    });

    it('refuses an eleventh image rather than growing the detail response', async () => {
      const { service, model, images } = buildService();
      model.findById.mockResolvedValue(productWithImages(10));

      await expect(
        service.addImage('p1', {} as never),
      ).rejects.toBeInstanceOf(BadRequestException);
      // Nothing reached Cloudinary, so no orphan is created by the refusal.
      expect(images.upload).not.toHaveBeenCalled();
    });

    it('saves the document before deleting the Cloudinary asset', async () => {
      const { service, model, images } = buildService();
      const product = productWithImages(2);
      model.findById.mockResolvedValue(product);
      const order: string[] = [];
      product.save.mockImplementation(() => {
        order.push('save');
        return Promise.resolve(product);
      });
      images.remove.mockImplementation(() => {
        order.push('remove');
        return Promise.resolve();
      });

      await service.removeImage('p1', 'cl-0');

      // A product listing an image whose asset is gone renders a broken
      // tile; an orphaned asset only costs storage. So the save wins.
      expect(order).toEqual(['save', 'remove']);
      expect(product.images.map((i) => i.publicId)).toEqual(['cl-1']);
    });

    it('rejects a publicId that is not on this product', async () => {
      const { service, model, images } = buildService();
      model.findById.mockResolvedValue(productWithImages(2));

      await expect(
        service.removeImage('p1', 'cl-somebody-elses'),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(images.remove).not.toHaveBeenCalled();
    });
  });

  describe('slugify', () => {
    it('turns punctuation into a boundary instead of dropping it', () => {
      expect(slugify('T-Shirt (V2)')).toBe('t-shirt-v2');
    });

    it('yields an empty string for a title with no Latin characters', () => {
      // The callers substitute a fallback base — an empty slug would make
      // the product unaddressable.
      expect(slugify('شورت')).toBe('');
    });
  });
});
