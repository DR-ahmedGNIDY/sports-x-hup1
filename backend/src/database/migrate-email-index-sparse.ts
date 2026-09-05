import 'dotenv/config';
import mongoose from 'mongoose';

// One-time operational script — the `users.email` unique index predates the
// `sparse: true` option on User.email (see users/schemas/user.schema.ts).
// Mongoose's autoIndex only calls createIndex, which is a no-op when an
// index of the same name already exists, even with different options — so
// environments seeded before that change carry a plain unique index that
// treats every document without an email (club-created player accounts,
// which sign in with a phone number instead) as sharing the same `null`
// value. The second such account then fails with E11000 on insert.
//
// Idempotent: drops `email_1` only if it exists and isn't already sparse,
// then (re)creates it correctly. Safe to run against an environment that's
// already fixed. Run with: npm run migrate:email-index-sparse
async function migrateEmailIndexSparse() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const collection = mongoose.connection.db!.collection('users');
  const indexes = await collection.indexes();
  const emailIndex = indexes.find((index) => index.name === 'email_1');

  if (!emailIndex) {
    // eslint-disable-next-line no-console
    console.log('No email_1 index found — nothing to do.');
  } else if (emailIndex.sparse) {
    // eslint-disable-next-line no-console
    console.log('email_1 index is already sparse — nothing to do.');
  } else {
    await collection.dropIndex('email_1');
    await collection.createIndex(
      { email: 1 },
      { unique: true, sparse: true, name: 'email_1' },
    );
    // eslint-disable-next-line no-console
    console.log('Rebuilt email_1 as a sparse unique index.');
  }

  await mongoose.disconnect();
}

migrateEmailIndexSparse().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Email index migration failed:', error);
  process.exit(1);
});
