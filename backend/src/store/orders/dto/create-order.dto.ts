import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEmail,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class OrderLineDto {
  @IsMongoId()
  productId: string;

  @IsMongoId()
  variantId: string;

  // Capped per line so a single request cannot ask to reserve the whole
  // warehouse. The real limit is the variant's stock, checked server-side.
  @IsInt()
  @Min(1)
  @Max(50)
  quantity: number;

  // Deliberately no price field. The client says what it wants, never what
  // it costs — every amount on the order is resolved from the database at
  // checkout, so a tampered request buys nothing at a discount.
}

export class ShippingAddressDto {
  @IsString()
  @MaxLength(120)
  fullName: string;

  // Egyptian mobile, the form the courier will actually dial. Validated
  // here rather than at the front end alone, since a guest order has no
  // account to fall back to if the number is wrong.
  @IsString()
  @Matches(/^(\+20|0)?1[0125][0-9]{8}$/, {
    message: 'phone must be a valid Egyptian mobile number.',
  })
  phone: string;

  @IsString()
  @MaxLength(40)
  governorateCode: string;

  @IsString()
  @MaxLength(120)
  city: string;

  @IsString()
  @MaxLength(400)
  street: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

export class CreateOrderDto {
  // Required even when the request carries a session token: a signed-in
  // club account ordering for someone else still needs a delivery contact,
  // and it is the guest's only handle on the order afterwards.
  @IsEmail()
  @MaxLength(200)
  email: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => OrderLineDto)
  lines: OrderLineDto[];

  @ValidateNested()
  @Type(() => ShippingAddressDto)
  address: ShippingAddressDto;
}
