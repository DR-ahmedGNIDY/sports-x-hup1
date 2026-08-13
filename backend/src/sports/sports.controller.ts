import { Controller, Get, Query } from '@nestjs/common';
import { SportsService } from './sports.service';
import { ListSkillCategoriesDto } from './dto/list-skill-categories.dto';

@Controller('sports')
export class SportsController {
  constructor(private readonly sportsService: SportsService) {}

  // Registered ahead of any future `:id`-style route on this controller so
  // "categories" is never matched as a sport id.
  @Get('categories')
  async findCategories(@Query() dto: ListSkillCategoriesDto) {
    const categories = await this.sportsService.findCategories(dto.sport);
    return categories.map((category) => ({
      id: category._id.toString(),
      name: category.name,
    }));
  }

  @Get()
  async findAll() {
    const sports = await this.sportsService.findAll();
    return sports.map((sport) => ({
      id: sport._id.toString(),
      name: sport.name,
    }));
  }
}
