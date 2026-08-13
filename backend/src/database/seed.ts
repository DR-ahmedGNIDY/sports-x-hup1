import 'dotenv/config';
import mongoose from 'mongoose';
import { Country, CountrySchema } from '../countries/schemas/country.schema';
import { Sport, SportSchema } from '../sports/schemas/sport.schema';
import {
  SkillCategory,
  SkillCategorySchema,
} from '../sports/schemas/skill-category.schema';

const SPORTS = [
  'Football',
  'Basketball',
  'Volleyball',
  'Handball',
  'Swimming',
  'Gymnastics',
];

const SKILL_CATEGORIES: Record<string, string[]> = {
  Football: [
    'Passing',
    'Receiving',
    'Shooting',
    'Dribbling',
    'Defending',
    'Heading',
    'Set Pieces',
  ],
  Basketball: [
    'Passing',
    'Receiving',
    'Shooting',
    'Dribbling',
    'Defense',
    'Rebounding',
  ],
  Volleyball: [
    'Serving',
    'Reception',
    'Setting',
    'Attacking',
    'Blocking',
    'Defense',
  ],
  Handball: [
    'Passing',
    'Receiving',
    'Shooting',
    'Dribbling',
    'Defense',
    'Goalkeeping',
  ],
  Swimming: [
    'Freestyle',
    'Backstroke',
    'Breaststroke',
    'Butterfly',
    'Starts & Turns',
    'Endurance',
  ],
  Gymnastics: [
    'Floor Exercise',
    'Vault',
    'Balance Beam',
    'Bars',
    'Strength',
    'Flexibility',
  ],
};

const COUNTRIES: Array<{ name: string; code: string }> = [
  { name: 'Egypt', code: 'EG' },
  { name: 'Saudi Arabia', code: 'SA' },
  { name: 'United Arab Emirates', code: 'AE' },
  { name: 'Qatar', code: 'QA' },
  { name: 'Kuwait', code: 'KW' },
  { name: 'Jordan', code: 'JO' },
  { name: 'Morocco', code: 'MA' },
  { name: 'Tunisia', code: 'TN' },
  { name: 'Algeria', code: 'DZ' },
  { name: 'Lebanon', code: 'LB' },
  { name: 'Iraq', code: 'IQ' },
  { name: 'Turkey', code: 'TR' },
  { name: 'United Kingdom', code: 'GB' },
  { name: 'France', code: 'FR' },
  { name: 'Germany', code: 'DE' },
  { name: 'Spain', code: 'ES' },
  { name: 'Italy', code: 'IT' },
  { name: 'Portugal', code: 'PT' },
  { name: 'Netherlands', code: 'NL' },
  { name: 'Brazil', code: 'BR' },
  { name: 'Argentina', code: 'AR' },
  { name: 'United States', code: 'US' },
];

async function seed() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sportxhub';
  await mongoose.connect(uri);

  const SportModel = mongoose.model(Sport.name, SportSchema);
  const CountryModel = mongoose.model(Country.name, CountrySchema);
  const SkillCategoryModel = mongoose.model(
    SkillCategory.name,
    SkillCategorySchema,
  );

  for (const name of SPORTS) {
    await SportModel.updateOne({ name }, { $set: { name } }, { upsert: true });
  }
  // Sports reduction: drop any previously-seeded sport that's no longer in
  // the roster (Tennis, Futsal, Rugby, Cricket, Baseball, Ice Hockey, Field
  // Hockey, Table Tennis, Badminton, Boxing, Athletics).
  await SportModel.deleteMany({ name: { $nin: SPORTS } });

  for (const country of COUNTRIES) {
    await CountryModel.updateOne(
      { code: country.code },
      { $set: country },
      { upsert: true },
    );
  }

  let categoryCount = 0;
  for (const sport of SPORTS) {
    const categories = SKILL_CATEGORIES[sport] ?? [];
    for (const [index, name] of categories.entries()) {
      await SkillCategoryModel.updateOne(
        { sport, name },
        { $set: { sport, name, order: index } },
        { upsert: true },
      );
      categoryCount += 1;
    }
  }
  // Keep skill categories consistent with the current sport roster.
  await SkillCategoryModel.deleteMany({ sport: { $nin: SPORTS } });

  // eslint-disable-next-line no-console
  console.log(
    `Seeded ${SPORTS.length} sports, ${categoryCount} skill categories and ${COUNTRIES.length} countries.`,
  );
  await mongoose.disconnect();
}

seed().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Seed failed:', error);
  process.exit(1);
});
