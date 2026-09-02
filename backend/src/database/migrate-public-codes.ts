import 'dotenv/config';
import mongoose from 'mongoose';
import {
  ClubProfile,
  ClubProfileSchema,
} from '../clubs/schemas/club-profile.schema';
import {
  PlayerProfile,
  PlayerProfileSchema,
} from '../players/schemas/player-profile.schema';
import { Counter, CounterSchema } from '../public-codes/schemas/counter.schema';

// One-time operational script — clubs and players gained a public, shareable
// code (CLB-000123 / PLY-000123) with the Invitations feature. New and
// freshly-loaded profiles get one lazily via ensurePublicCode; this assigns
// them in bulk so every existing profile is searchable immediately instead of
// only after its owner next signs in.
//
// Idempotent: profiles that already have a code are skipped, so re-running it
// (or running it while the app is live and handing out codes lazily) can't
// renumber anybody. Run with: npm run migrate:public-codes
const CODE_DIGITS = 6;

async function nextCode(
  CounterModel: mongoose.Model<Counter>,
  prefix: string,
): Promise<string> {
  const counter = await CounterModel.findOneAndUpdate(
    { _id: prefix },
    { $inc: { seq: 1 } },
    { upsert: true, new: true },
  );
  return `${prefix}-${String(counter.seq).padStart(CODE_DIGITS, '0')}`;
}

async function backfill(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  Model: mongoose.Model<any>,
  CounterModel: mongoose.Model<Counter>,
  prefix: string,
): Promise<number> {
  // Batched by cursor rather than loading every profile at once — this runs
  // against the full collection.
  const cursor = Model.find({
    publicCode: { $in: [null, undefined] },
  })
    .select('_id')
    .cursor();

  let assigned = 0;
  for await (const doc of cursor) {
    const publicCode = await nextCode(CounterModel, prefix);
    // Conditional on the code still being absent, so a profile that picked
    // one up lazily while this script was running keeps the code it already
    // published rather than being renumbered underneath its owner.
    const result = await Model.updateOne(
      { _id: doc._id, publicCode: { $in: [null, undefined] } },
      { $set: { publicCode } },
    );
    if (result.modifiedCount > 0) assigned += 1;
  }
  return assigned;
}

async function migratePublicCodes() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const CounterModel = mongoose.model(Counter.name, CounterSchema);
  const ClubProfileModel = mongoose.model(ClubProfile.name, ClubProfileSchema);
  const PlayerProfileModel = mongoose.model(
    PlayerProfile.name,
    PlayerProfileSchema,
  );

  const clubs = await backfill(ClubProfileModel, CounterModel, 'CLB');
  const players = await backfill(PlayerProfileModel, CounterModel, 'PLY');

  // eslint-disable-next-line no-console
  console.log(`Assigned ${clubs} club code(s) and ${players} player code(s).`);
  await mongoose.disconnect();
}

migratePublicCodes().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Public code migration failed:', error);
  process.exit(1);
});
