import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Sport, SportSchema } from './schemas/sport.schema';
import {
  SkillCategory,
  SkillCategorySchema,
} from './schemas/skill-category.schema';
import { SportsController } from './sports.controller';
import { SportsService } from './sports.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Sport.name, schema: SportSchema },
      { name: SkillCategory.name, schema: SkillCategorySchema },
    ]),
  ],
  controllers: [SportsController],
  providers: [SportsService],
  exports: [SportsService],
})
export class SportsModule {}
