import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Counter } from './schemas/counter.schema';

/** Sequence names — also the literal prefix of every code they produce. */
export enum PublicCodePrefix {
  CLUB = 'CLB',
  PLAYER = 'PLY',
}

// Six digits covers 999,999 profiles per sequence; past that the code simply
// grows a digit rather than wrapping or colliding (padStart is a floor, not a
// cap), so nothing breaks at the boundary.
const CODE_DIGITS = 6;

// Accepts the canonical form and anything longer, e.g. "PLY-1000000".
const CODE_PATTERN = /^(CLB|PLY)-\d{6,}$/;

@Injectable()
export class PublicCodesService {
  constructor(
    @InjectModel(Counter.name) private readonly counterModel: Model<Counter>,
  ) {}

  // Atomic: `$inc` with `upsert` is a single document operation, so two
  // profiles created at the same instant get two different numbers without a
  // transaction (which local standalone MongoDB wouldn't support anyway).
  async allocate(prefix: PublicCodePrefix): Promise<string> {
    const counter = await this.counterModel.findOneAndUpdate(
      { _id: prefix },
      { $inc: { seq: 1 } },
      { upsert: true, new: true },
    );
    return `${prefix}-${String(counter.seq).padStart(CODE_DIGITS, '0')}`;
  }

  // Callers pass user input straight in — codes are shared by copy/paste and
  // typed by hand, so tolerate whitespace and lower case rather than making
  // the user match the display form exactly. Returns null (not a thrown
  // error) for anything that isn't a code at all, so a lookup can answer
  // "not found" without a database round-trip.
  static normalize(raw: string): string | null {
    const candidate = raw.trim().toUpperCase();
    return CODE_PATTERN.test(candidate) ? candidate : null;
  }

  static normalizeFor(raw: string, prefix: PublicCodePrefix): string | null {
    const normalized = PublicCodesService.normalize(raw);
    if (!normalized || !normalized.startsWith(`${prefix}-`)) return null;
    return normalized;
  }
}
