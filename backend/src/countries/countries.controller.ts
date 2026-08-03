import { Controller, Get } from '@nestjs/common';
import { CountriesService } from './countries.service';

@Controller('countries')
export class CountriesController {
  constructor(private readonly countriesService: CountriesService) {}

  @Get()
  async findAll() {
    const countries = await this.countriesService.findAll();
    return countries.map((country) => ({
      id: country._id.toString(),
      name: country.name,
      code: country.code,
    }));
  }
}
