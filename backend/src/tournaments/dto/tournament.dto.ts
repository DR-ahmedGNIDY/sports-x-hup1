import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  ParticipantType,
  TournamentFormat,
} from '../schemas/tournament.schemas';

const DATE = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;

class ScoringDto {
  @IsOptional()
  @IsIn(['goals', 'sets'])
  mode?: 'goals' | 'sets';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @IsIn([1, 3, 5, 7], { message: 'bestOf must be 1, 3, 5 or 7.' })
  bestOf?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pointsPerSet?: number;

  @IsOptional()
  @IsBoolean()
  winByTwo?: boolean;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  maxPointsPerSet?: number | null;
}

class LeagueDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(10)
  winPoints?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(10)
  drawPoints?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(10)
  lossPoints?: number;

  @IsOptional()
  @IsBoolean()
  doubleRound?: boolean;

  @IsOptional()
  @IsBoolean()
  allowDraws?: boolean;
}

class GroupsDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  @Max(16)
  count?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(8)
  qualifiersPerGroup?: number;
}

class KnockoutDto {
  @IsOptional()
  @IsBoolean()
  penaltiesEnabled?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(20)
  penaltiesCount?: number;
}

/** Everything optional: the same shape serves create and update. */
export class UpsertTournamentDto {
  @IsOptional()
  @IsString()
  @Length(2, 150)
  name?: string;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsMongoId()
  sportId?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  ageGroup?: string;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Matches(DATE, { message: 'startDate must be YYYY-MM-DD.' })
  startDate?: string | null;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Matches(DATE, { message: 'endDate must be YYYY-MM-DD.' })
  endDate?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @IsOptional()
  @IsEnum(ParticipantType)
  participantType?: ParticipantType;

  @IsOptional()
  @IsEnum(TournamentFormat)
  format?: TournamentFormat;

  @IsOptional()
  @IsIn(['random', 'directed'])
  drawMode?: 'random' | 'directed';

  @IsOptional()
  @ValidateNested()
  @Type(() => ScoringDto)
  scoring?: ScoringDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => LeagueDto)
  league?: LeagueDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => GroupsDto)
  groups?: GroupsDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => KnockoutDto)
  knockout?: KnockoutDto;

  @IsOptional()
  @IsBoolean()
  visibleToPlayers?: boolean;
}

export class ParticipantDto {
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsMongoId({ each: true })
  playerUserIds?: string[];

  /** Team name; an individual entry is always named after its player. */
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsMongoId()
  captainUserId?: string | null;
}

export class ParticipantOrderDto {
  @IsArray()
  @IsMongoId({ each: true })
  order: string[];
}

export class UpdateFixtureDto {
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Matches(DATE, { message: 'date must be YYYY-MM-DD.' })
  date?: string | null;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @Matches(TIME, { message: 'time must be HH:mm.' })
  time?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  location?: string;

  // The two sides — swapped or replaced before any result is in.
  @IsOptional()
  @IsMongoId()
  aId?: string;

  @IsOptional()
  @IsMongoId()
  bId?: string;
}

class SetScoreDto {
  @Type(() => Number)
  @IsInt()
  @Min(0)
  a: number;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  b: number;
}

export class RecordResultDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  scoreA?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  scoreB?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SetScoreDto)
  sets?: SetScoreDto[];

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  penaltiesA?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  penaltiesB?: number;
}
