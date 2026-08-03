import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Sport, SportDocument } from './schemas/sport.schema';

@Injectable()
export class SportsService {
  constructor(
    @InjectModel(Sport.name) private readonly sportModel: Model<Sport>,
  ) {}

  findAll(): Promise<SportDocument[]> {
    return this.sportModel.find().sort({ name: 1 });
  }
}
