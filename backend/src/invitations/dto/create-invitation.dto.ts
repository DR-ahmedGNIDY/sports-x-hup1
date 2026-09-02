import {
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { INVITATION_MESSAGE_MAX_LENGTH } from '../schemas/club-player-invitation.schema';

// Both DTOs accept the counterpart either by public code (how the UI finds
// someone: "PLY-000123") or by profile id (how it links from a profile page
// already on screen). Exactly one is required — the service rejects "neither"
// rather than a validator, because "either/or" isn't expressible per-field
// and a wrong error shape here would leak which branch was taken.
//
// Nothing else is accepted from the client. Direction, sender, recipient,
// status, expiry and the canonical club/player pair are all derived
// server-side, so the global ValidationPipe's `whitelist: true` plus this
// deliberately tiny surface is the mass-assignment defence.

class BaseCreateInvitationDto {
  @IsOptional()
  @IsString()
  @MaxLength(INVITATION_MESSAGE_MAX_LENGTH)
  message?: string;
}

export class CreateClubToPlayerInvitationDto extends BaseCreateInvitationDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  playerCode?: string;

  @IsOptional()
  @IsMongoId()
  playerId?: string;
}

export class CreatePlayerToClubInvitationDto extends BaseCreateInvitationDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  clubCode?: string;

  @IsOptional()
  @IsMongoId()
  clubId?: string;
}
