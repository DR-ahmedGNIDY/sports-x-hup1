import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Min } from 'class-validator';
import { InvitationStatus } from '../schemas/club-player-invitation.schema';

export class ListInvitationsDto {
  // Absent means "every status" — the tab UI filters to PENDING, history
  // views want the lot.
  @IsOptional()
  @IsEnum(InvitationStatus)
  status?: InvitationStatus;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;
}
