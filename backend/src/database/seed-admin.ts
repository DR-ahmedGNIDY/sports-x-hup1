import 'dotenv/config';
import * as bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import {
  User,
  UserSchema,
  UserRole,
  UserStatus,
} from '../users/schemas/user.schema';

const PASSWORD_SALT_ROUNDS = 10;

// One-time operational script — the only way an ADMIN account is ever
// created (RegisterDto rejects 'ADMIN', see auth/dto/register.dto.ts).
// Run with: npm run seed:admin
// Requires ADMIN_EMAIL and ADMIN_PASSWORD in the environment.
async function seedAdmin() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) {
    throw new Error(
      'Set ADMIN_EMAIL and ADMIN_PASSWORD before running this script.',
    );
  }

  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const UserModel = mongoose.model(User.name, UserSchema);
  const passwordHash = await bcrypt.hash(password, PASSWORD_SALT_ROUNDS);

  await UserModel.updateOne(
    { email: email.toLowerCase() },
    {
      $set: {
        email,
        passwordHash,
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
      },
    },
    { upsert: true },
  );

  // eslint-disable-next-line no-console
  console.log(`Admin account ready: ${email}`);
  await mongoose.disconnect();
}

seedAdmin().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Admin seed failed:', error);
  process.exit(1);
});
