import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { CouponType } from '../../schemas/coupon.schema';

export class UpsertCouponDto {
  // Letters, digits and hyphens only: a code is dictated over the phone and
  // typed on a keyboard the customer may be switching languages on.
  @IsString()
  @MaxLength(32)
  @Matches(/^[A-Za-z0-9-]+$/, {
    message: 'code must be letters, digits and hyphens only.',
  })
  code: string;

  @IsEnum(CouponType)
  type: CouponType;

  // Percent or piastres, depending on `type` — the service rejects a
  // percentage above 100, which is the only bound that depends on the type.
  @IsInt()
  @Min(1)
  value: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  minSubtotalMinor?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  maxRedemptions?: number;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  startsAt?: Date;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  endsAt?: Date;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
