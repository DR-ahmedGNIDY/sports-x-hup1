import { Type } from 'class-transformer';
import { IsObject, IsOptional, IsString, ArrayUnique } from 'class-validator';

export class UpdateRosterDto {
  @IsString({ each: true })
  @ArrayUnique()
  @Type(() => String)
  playerIds: string[];

  // playerId -> position override. Any playerId not present here defaults
  // to that player's own PlayerProfile.position.
  @IsOptional()
  @IsObject()
  positions?: Record<string, string>;
}
