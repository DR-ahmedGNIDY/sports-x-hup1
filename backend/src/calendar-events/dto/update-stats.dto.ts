import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsMongoId,
  Min,
  ValidateNested,
} from 'class-validator';

export class MatchStatEntryDto {
  @IsMongoId()
  playerId: string;

  @IsInt()
  @Min(0)
  goals: number;

  @IsInt()
  @Min(0)
  assists: number;

  @IsInt()
  @Min(0)
  chancesCreated: number;

  @IsInt()
  @Min(0)
  keyPasses: number;

  @IsInt()
  @Min(0)
  keyDefensiveActions: number;

  @IsInt()
  @Min(0)
  saves: number;
}

export class UpdateStatsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MatchStatEntryDto)
  entries: MatchStatEntryDto[];
}
