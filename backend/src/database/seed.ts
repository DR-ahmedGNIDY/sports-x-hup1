import 'dotenv/config';
import mongoose from 'mongoose';
import { Country, CountrySchema } from '../countries/schemas/country.schema';
import { Sport, SportSchema } from '../sports/schemas/sport.schema';

const SPORTS = [
  'Football',
  'Basketball',
  'Tennis',
  'Volleyball',
  'Handball',
  'Futsal',
  'Rugby',
  'Cricket',
  'Baseball',
  'Ice Hockey',
  'Field Hockey',
  'Table Tennis',
  'Badminton',
  'Boxing',
  'Athletics',
  'Swimming',
];

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

  for (const name of SPORTS) {
    await SportModel.updateOne({ name }, { $set: { name } }, { upsert: true });
  }

  for (const country of COUNTRIES) {
    await CountryModel.updateOne(
      { code: country.code },
      { $set: country },
      { upsert: true },
    );
  }

  // eslint-disable-next-line no-console
  console.log(
    `Seeded ${SPORTS.length} sports and ${COUNTRIES.length} countries.`,
  );
  await mongoose.disconnect();
}

seed().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Seed failed:', error);
  process.exit(1);
});
