import { IsEmail, IsString, MaxLength } from 'class-validator';

// A guest has no session, so retrieving their own order needs something
// only they hold. The order number alone will not do — it is sequential and
// therefore guessable — so the email it was placed with has to match too.
export class TrackOrderDto {
  @IsString()
  @MaxLength(40)
  orderNumber: string;

  @IsEmail()
  @MaxLength(200)
  email: string;
}
