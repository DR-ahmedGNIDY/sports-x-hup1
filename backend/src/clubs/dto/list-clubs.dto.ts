import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class ListClubsDto {
  // Free text matched against the club's name. Length-capped because it
  // reaches a regex: an unbounded pattern is a cheap way to make the
  // database work hard on someone else's behalf.
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
