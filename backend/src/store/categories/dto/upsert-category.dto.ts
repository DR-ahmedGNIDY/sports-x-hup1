import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsMongoId,
  IsOptional,
  Min,
  ValidateNested,
} from 'class-validator';
import { LocalizedTextDto } from '../../dto/localized-text.dto';

export class UpsertCategoryDto {
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  name: LocalizedTextDto;

  @IsOptional()
  @IsMongoId()
  parentId?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
