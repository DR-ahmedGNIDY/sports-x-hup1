import 'dotenv/config';
import mongoose from 'mongoose';
import {
  StoreCategory,
  StoreCategorySchema,
} from '../store/schemas/category.schema';

// The storefront's two axes: who the product is for, and what kind of thing
// it is. They are modelled as department > type rather than as two
// independent facets because the catalogue's one level of nesting (see
// `StoreCategory.parentId`) is what the navigation and the URLs are built on:
// `/store/c/men` lists the whole department, `/store/c/men-shoes` one shelf.
//
// Every product is filed on a leaf. A department carries no products of its
// own — listing it expands to its children, which is what
// `StoreCategoriesService.selfAndDescendantIds` is for.
// `possessive` is carried rather than derived: "Men" takes 's and "Kids"
// takes a bare apostrophe, and no rule short of listing them gets both right.
const DEPARTMENTS: Array<{
  slug: string;
  en: string;
  possessive: string;
  ar: string;
}> = [
  { slug: 'men', en: 'Men', possessive: "Men's", ar: 'رجالي' },
  { slug: 'women', en: 'Women', possessive: "Women's", ar: 'حريمي' },
  { slug: 'kids', en: 'Kids', possessive: "Kids'", ar: 'أطفالي' },
];

const TYPES: Array<{ slug: string; en: string; ar: string }> = [
  { slug: 'clothing', en: 'Clothing', ar: 'ملابس' },
  { slug: 'shoes', en: 'Shoes', ar: 'أحذية' },
  { slug: 'equipment', en: 'Equipment', ar: 'أدوات رياضية' },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not set — see backend/.env.example.');
  }

  await mongoose.connect(uri);
  const model = mongoose.model(StoreCategory.name, StoreCategorySchema);

  let created = 0;
  let total = 0;

  // Upsert on the slug, which is the published address and so the only
  // stable identity a category has. `$setOnInsert` guards `isActive`: a
  // department the merchant has since hidden for the season must not come
  // back because someone re-ran the seed. Names, parentage and menu order
  // are ours, so those stay in step.
  async function upsert(
    slug: string,
    name: { en: string; ar: string },
    sortOrder: number,
    parentId?: mongoose.Types.ObjectId,
  ): Promise<mongoose.Types.ObjectId> {
    total++;
    const result = await model.updateOne(
      { slug },
      {
        $set: { name, sortOrder, ...(parentId ? { parentId } : {}) },
        $setOnInsert: { isActive: true },
      },
      { upsert: true },
    );
    if (result.upsertedCount > 0) {
      created++;
      return result.upsertedId as mongoose.Types.ObjectId;
    }
    // Already present: read back the id the children need to point at.
    const existing = await model.findOne({ slug }, { _id: 1 }).orFail();
    return existing._id;
  }

  for (const [index, department] of DEPARTMENTS.entries()) {
    // Departments occupy 0, 10, 20 so a merchant can slot one in between
    // without renumbering the rest.
    const parentId = await upsert(
      department.slug,
      { en: department.en, ar: department.ar },
      index * 10,
    );

    for (const [typeIndex, type] of TYPES.entries()) {
      await upsert(
        `${department.slug}-${type.slug}`,
        {
          en: `${department.possessive} ${type.en}`,
          ar: `${type.ar} ${department.ar}`,
        },
        typeIndex,
        parentId,
      );
    }
  }

  // eslint-disable-next-line no-console
  console.log(
    `Store categories: ${total} departments and shelves ensured (${created} created; hidden ones left hidden).`,
  );
  await mongoose.disconnect();
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Failed to seed store categories.', error);
  process.exit(1);
});
