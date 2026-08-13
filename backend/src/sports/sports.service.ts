import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Sport, SportDocument } from './schemas/sport.schema';
import {
  SkillCategory,
  SkillCategoryDocument,
} from './schemas/skill-category.schema';

@Injectable()
export class SportsService {
  constructor(
    @InjectModel(Sport.name) private readonly sportModel: Model<Sport>,
    @InjectModel(SkillCategory.name)
    private readonly skillCategoryModel: Model<SkillCategory>,
  ) {}

  findAll(): Promise<SportDocument[]> {
    return this.sportModel.find().sort({ name: 1 });
  }

  findCategories(sport: string): Promise<SkillCategoryDocument[]> {
    return this.skillCategoryModel.find({ sport }).sort({ order: 1 });
  }

  // Guards client-supplied `sport` values (e.g. a Community feed filter)
  // against the seeded catalog, so a typo'd/unknown sport surfaces as a
  // clear 400 instead of silently matching nothing.
  async assertSportExists(sport: string): Promise<void> {
    const exists = await this.sportModel.exists({ name: sport });
    if (!exists) {
      throw new BadRequestException(`Unknown sport "${sport}".`);
    }
  }

  // Guards a client-supplied `category` against the seeded catalog for the
  // given sport — used where the category is picked by the caller (e.g.
  // video upload), not applied as an optional filter.
  async assertCategoryExists(sport: string, category: string): Promise<void> {
    const exists = await this.skillCategoryModel.exists({
      sport,
      name: category,
    });
    if (!exists) {
      throw new BadRequestException(
        `Unknown category "${category}" for sport "${sport}".`,
      );
    }
  }
}
