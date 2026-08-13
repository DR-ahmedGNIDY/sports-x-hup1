import { IsNotEmpty, IsString } from 'class-validator';

export class ListSkillCategoriesDto {
  @IsString()
  @IsNotEmpty()
  sport: string;
}
