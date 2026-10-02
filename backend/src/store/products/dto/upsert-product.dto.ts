import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { ProductBadge } from '../../product-badge.enum';
import {
  LocalizedBodyDto,
  LocalizedTextDto,
} from '../../dto/localized-text.dto';

export class ProductVariantDto {
  @IsOptional()
  @IsString()
  @MaxLength(60)
  size?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  colour?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  sku?: string;

  @IsInt()
  @Min(0)
  stock: number;
}

export class ProductColourDto {
  @IsString()
  @MaxLength(60)
  name: string;

  @Matches(/^#[0-9a-fA-F]{6}$/, { message: 'hex must look like #a1b2c3.' })
  hex: string;
}

export class UpsertProductDto {
  @ValidateNested()
  @Type(() => LocalizedTextDto)
  title: LocalizedTextDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocalizedBodyDto)
  description?: LocalizedBodyDto;

  @IsMongoId()
  categoryId: string;

  @IsInt()
  @Min(0)
  priceMinor: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  compareAtPriceMinor?: number;

  // Bounded so one product cannot be given a gallery large enough to make
  // its own detail response the slowest thing in the store.
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => ProductVariantDto)
  variants?: ProductVariantDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @ValidateNested({ each: true })
  @Type(() => ProductColourDto)
  colours?: ProductColourDto[];

  @IsOptional()
  @IsEnum(ProductBadge)
  badge?: ProductBadge;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  tags?: string[];

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
