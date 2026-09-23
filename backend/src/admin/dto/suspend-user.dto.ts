import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { SuspensionDuration } from '../../users/suspension';

export class SuspendUserDto {
  // One of the fixed terms the dashboard offers — one month, three months,
  // one year, or permanent. See `users/suspension.ts` for why this is a
  // closed set rather than a caller-supplied end date.
  @IsEnum(SuspensionDuration)
  duration: SuspensionDuration;

  // Internal note for other admins; never shown to the suspended user.
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
