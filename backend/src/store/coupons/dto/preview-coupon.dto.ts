import { Type } from 'class-transformer';
import { IsInt, IsString, MaxLength, Min } from 'class-validator';

/// What the cart sends to price a code before checkout. The subtotal is the
/// client's, which is fine here: this is a quote, and checkout re-prices
/// everything from the database before a piastre is committed.
export class PreviewCouponDto {
  @IsString()
  @MaxLength(32)
  code: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  subtotalMinor: number;
}
