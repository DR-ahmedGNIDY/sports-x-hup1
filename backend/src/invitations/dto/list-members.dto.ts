import { Type } from 'class-transformer';
import { IsInt, IsOptional, Min } from 'class-validator';

// The whole query surface of the public roster endpoint: a page number and
// nothing else. Which club is being read comes from the path, and which
// players may appear is the server's decision (PUBLIC only) rather than a
// filter the caller can widen.
export class ListMembersDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
