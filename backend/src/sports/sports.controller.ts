import { Controller, Get } from '@nestjs/common';
import { SportsService } from './sports.service';

@Controller('sports')
export class SportsController {
  constructor(private readonly sportsService: SportsService) {}

  @Get()
  async findAll() {
    const sports = await this.sportsService.findAll();
    return sports.map((sport) => ({
      id: sport._id.toString(),
      name: sport.name,
    }));
  }
}
