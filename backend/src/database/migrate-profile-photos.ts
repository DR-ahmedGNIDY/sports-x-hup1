import 'dotenv/config';
import mongoose from 'mongoose';
import {
  PlayerProfile,
  PlayerProfileSchema,
} from '../players/schemas/player-profile.schema';

// One-time operational script — profile photos used to live inside the
// `media` album array (tagged `isProfilePhoto: true`); they now live in
// their own `profilePhoto` field so uploading one no longer counts toward
// (or shows up in) the album. This moves any pre-existing flagged item out
// of `media` and into `profilePhoto` for every profile that has one.
// Run with: npm run migrate:profile-photos
async function migrateProfilePhotos() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const PlayerProfileModel = mongoose.model(
    PlayerProfile.name,
    PlayerProfileSchema,
  );

  const profiles = await PlayerProfileModel.find({
    'media.isProfilePhoto': true,
    profilePhoto: { $exists: false },
  });

  let migrated = 0;
  for (const profile of profiles) {
    const flagged = profile.media.find((item) => item.isProfilePhoto);
    if (!flagged) continue;

    profile.profilePhoto = {
      publicId: flagged.publicId,
      secureUrl: flagged.secureUrl,
    };
    profile.media = profile.media.filter(
      (item) => item._id?.toString() !== flagged._id?.toString(),
    ) as typeof profile.media;
    await profile.save();
    migrated += 1;
  }

  // eslint-disable-next-line no-console
  console.log(`Migrated ${migrated} profile photo(s) out of the album.`);
  await mongoose.disconnect();
}

migrateProfilePhotos().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Profile photo migration failed:', error);
  process.exit(1);
});
