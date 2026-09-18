import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { CoachPermission } from '../../club-access/coach-permission.enum';
import { INVITATION_MESSAGE_MAX_LENGTH } from '../../invitations/schemas/club-player-invitation.schema';

// Same deliberately tiny surface as the player invitation DTOs: the
// counterpart by code or by profile id, plus an optional note. Everything
// else is derived server-side.
class BaseDto {
  @IsOptional()
  @IsString()
  @MaxLength(INVITATION_MESSAGE_MAX_LENGTH)
  message?: string;
}

export class CreateClubToCoachInvitationDto extends BaseDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  coachCode?: string;

  @IsOptional()
  @IsMongoId()
  coachId?: string;
}

export class CreateCoachToClubInvitationDto extends BaseDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  clubCode?: string;

  @IsOptional()
  @IsMongoId()
  clubId?: string;
}

export class SetCoachPermissionsDto {
  @IsArray()
  @ArrayMaxSize(20)
  @IsEnum(CoachPermission, { each: true })
  @Type(() => String)
  permissions: CoachPermission[];
}
