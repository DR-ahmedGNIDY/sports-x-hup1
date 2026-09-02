import 'dotenv/config';
import mongoose from 'mongoose';
import {
  PlayerProfile,
  PlayerProfileSchema,
  ProfileVisibility,
} from '../players/schemas/player-profile.schema';

// One-time operational script, run deliberately and never on a schedule.
//
// Player profiles default to PRIVATE, and search only returns PUBLIC ones,
// so a profile stays invisible to every club until its owner opens it. On
// this deployment almost every profile was still sitting on the default and
// the operator asked for them all to be opened at once.
//
// This changes a privacy setting on behalf of people who did not ask for it
// and will not be told. That is a decision for whoever runs the service, not
// for this script, which is why it does nothing without --apply. No undo
// list is kept: the operator asked for none, so a reversal would mean
// setting every profile back by hand.
//
//   npm run migrate:profiles-public              # dry run, changes nothing
//   npm run migrate:profiles-public -- --apply   # writes
async function migrateProfilesPublic() {
  const apply = process.argv.includes('--apply');
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const PlayerProfileModel = mongoose.model(
    PlayerProfile.name,
    PlayerProfileSchema,
  );

  const hidden = await PlayerProfileModel.find(
    { visibility: ProfileVisibility.PRIVATE },
    { _id: 1, publicCode: 1, firstName: 1, lastName: 1 },
  ).lean();

  const total = await PlayerProfileModel.countDocuments();
  const alreadyPublic = total - hidden.length;

  // eslint-disable-next-line no-console
  console.log(
    `${total} profile(s): ${alreadyPublic} already PUBLIC, ${hidden.length} PRIVATE.`,
  );
  for (const p of hidden) {
    // eslint-disable-next-line no-console
    console.log(
      `  ${String(p.publicCode ?? '(no code)')}  ${String(p.firstName ?? '')} ${String(p.lastName ?? '')}`.trimEnd(),
    );
  }

  if (!apply) {
    // eslint-disable-next-line no-console
    console.log('\nDry run — nothing written. Re-run with --apply to change.');
    await mongoose.disconnect();
    return;
  }

  if (hidden.length === 0) {
    // eslint-disable-next-line no-console
    console.log('Nothing to do.');
    await mongoose.disconnect();
    return;
  }

  const result = await PlayerProfileModel.updateMany(
    { _id: { $in: hidden.map((p) => p._id) } },
    { $set: { visibility: ProfileVisibility.PUBLIC } },
  );

  // eslint-disable-next-line no-console
  console.log(`Set ${result.modifiedCount} profile(s) to PUBLIC.`);
  await mongoose.disconnect();
}

migrateProfilesPublic().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Visibility migration failed:', error);
  process.exit(1);
});
