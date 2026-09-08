import 'dotenv/config';
import mongoose from 'mongoose';
import {
  ShippingZone,
  ShippingZoneSchema,
} from '../store/schemas/shipping-zone.schema';

// Egypt's 27 governorates, in the order the checkout picker should list
// them: the three the bulk of orders go to first, then the rest roughly by
// region. Fees are starting values a merchant is expected to edit in the
// dashboard — they are a commercial decision, not a fact about geography.
//
// Amounts are piastres, like every other amount in the store: 5500 is
// EGP 55.00.
const GOVERNORATES: Array<{
  code: string;
  en: string;
  ar: string;
  feeMinor: number;
}> = [
  { code: 'cairo', en: 'Cairo', ar: 'القاهرة', feeMinor: 5500 },
  { code: 'giza', en: 'Giza', ar: 'الجيزة', feeMinor: 5500 },
  { code: 'alexandria', en: 'Alexandria', ar: 'الإسكندرية', feeMinor: 6500 },
  { code: 'qalyubia', en: 'Qalyubia', ar: 'القليوبية', feeMinor: 6500 },
  { code: 'sharqia', en: 'Sharqia', ar: 'الشرقية', feeMinor: 7000 },
  { code: 'dakahlia', en: 'Dakahlia', ar: 'الدقهلية', feeMinor: 7000 },
  { code: 'gharbia', en: 'Gharbia', ar: 'الغربية', feeMinor: 7000 },
  { code: 'monufia', en: 'Monufia', ar: 'المنوفية', feeMinor: 7000 },
  { code: 'beheira', en: 'Beheira', ar: 'البحيرة', feeMinor: 7000 },
  {
    code: 'kafr-el-sheikh',
    en: 'Kafr El Sheikh',
    ar: 'كفر الشيخ',
    feeMinor: 7500,
  },
  { code: 'damietta', en: 'Damietta', ar: 'دمياط', feeMinor: 7500 },
  { code: 'port-said', en: 'Port Said', ar: 'بورسعيد', feeMinor: 7500 },
  { code: 'ismailia', en: 'Ismailia', ar: 'الإسماعيلية', feeMinor: 7500 },
  { code: 'suez', en: 'Suez', ar: 'السويس', feeMinor: 7500 },
  { code: 'faiyum', en: 'Faiyum', ar: 'الفيوم', feeMinor: 7500 },
  { code: 'beni-suef', en: 'Beni Suef', ar: 'بني سويف', feeMinor: 7500 },
  { code: 'minya', en: 'Minya', ar: 'المنيا', feeMinor: 8500 },
  { code: 'asyut', en: 'Asyut', ar: 'أسيوط', feeMinor: 8500 },
  { code: 'sohag', en: 'Sohag', ar: 'سوهاج', feeMinor: 8500 },
  { code: 'qena', en: 'Qena', ar: 'قنا', feeMinor: 9000 },
  { code: 'luxor', en: 'Luxor', ar: 'الأقصر', feeMinor: 9000 },
  { code: 'aswan', en: 'Aswan', ar: 'أسوان', feeMinor: 9500 },
  { code: 'red-sea', en: 'Red Sea', ar: 'البحر الأحمر', feeMinor: 11000 },
  {
    code: 'new-valley',
    en: 'New Valley',
    ar: 'الوادي الجديد',
    feeMinor: 12000,
  },
  { code: 'matrouh', en: 'Matrouh', ar: 'مطروح', feeMinor: 11000 },
  { code: 'north-sinai', en: 'North Sinai', ar: 'شمال سيناء', feeMinor: 12000 },
  { code: 'south-sinai', en: 'South Sinai', ar: 'جنوب سيناء', feeMinor: 12000 },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not set — see backend/.env.example.');
  }

  await mongoose.connect(uri);
  const model = mongoose.model(ShippingZone.name, ShippingZoneSchema);

  let created = 0;
  for (const [index, governorate] of GOVERNORATES.entries()) {
    // Upsert on `code`, and `$setOnInsert` for the fee: re-running the seed
    // must not undo a fee the merchant has since edited in the dashboard.
    // Only the display names are kept in step, since those are ours.
    const result = await model.updateOne(
      { code: governorate.code },
      {
        $set: {
          name: { en: governorate.en, ar: governorate.ar },
          sortOrder: index,
        },
        $setOnInsert: { feeMinor: governorate.feeMinor, isActive: true },
      },
      { upsert: true },
    );
    if (result.upsertedCount > 0) created++;
  }

  // eslint-disable-next-line no-console
  console.log(
    `Shipping zones: ${created} created, ${GOVERNORATES.length - created} already present (fees left untouched).`,
  );
  await mongoose.disconnect();
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Failed to seed shipping zones.', error);
  process.exit(1);
});
