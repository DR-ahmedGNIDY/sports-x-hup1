import { IsString } from 'class-validator';

export class DeleteAccountDto {
  // Re-entered by the user to confirm an irreversible action, so a stolen
  // or left-open session alone can't wipe the account.
  @IsString()
  password: string;
}
