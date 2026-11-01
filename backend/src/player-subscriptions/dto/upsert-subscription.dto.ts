import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { SubscriptionPlan } from '../schemas/player-subscription.schema';

const DATE_PATTERN = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

class SubscriptionFieldsDto {
  @IsEnum(SubscriptionPlan)
  plan: SubscriptionPlan;

  @Matches(DATE_PATTERN, { message: 'startDate must be YYYY-MM-DD.' })
  startDate: string;

  @Matches(DATE_PATTERN, { message: 'endDate must be YYYY-MM-DD.' })
  endDate: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  amountMinor: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  paidMinor?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

export class CreateSubscriptionDto extends SubscriptionFieldsDto {
  @IsMongoId()
  playerUserId: string;
}

// Every field optional: an edit is usually one thing — a payment coming in.
export class UpdateSubscriptionDto {
  @IsOptional()
  @IsEnum(SubscriptionPlan)
  plan?: SubscriptionPlan;

  @IsOptional()
  @Matches(DATE_PATTERN, { message: 'startDate must be YYYY-MM-DD.' })
  startDate?: string;

  @IsOptional()
  @Matches(DATE_PATTERN, { message: 'endDate must be YYYY-MM-DD.' })
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  amountMinor?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  paidMinor?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
