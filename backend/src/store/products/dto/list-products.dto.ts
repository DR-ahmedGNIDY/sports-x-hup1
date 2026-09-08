import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export enum ProductSort {
  NEWEST = 'newest',
  PRICE_ASC = 'price_asc',
  PRICE_DESC = 'price_desc',
}

export class ListProductsDto {
  // Length-capped for the same reason ListClubsDto caps its own: this
  // reaches the database as a query, and an unbounded one is a cheap way to
  // make it work hard on someone else's behalf.
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @IsOptional()
  @IsMongoId()
  categoryId?: string;

  // Accepts the slug too, so a link like /store/c/men-tops can be resolved
  // in one request rather than a lookup followed by a listing.
  @IsOptional()
  @IsString()
  @MaxLength(120)
  categorySlug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  size?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  colour?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minPriceMinor?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPriceMinor?: number;

  // `Type(() => Boolean)` would coerce the string "false" to true — every
  // non-empty string is truthy — so the flag is parsed explicitly.
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  featured?: boolean;

  @IsOptional()
  @IsEnum(ProductSort)
  sort?: ProductSort;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
