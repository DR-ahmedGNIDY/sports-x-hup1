import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  ValidateNested,
} from 'class-validator';

class PushKeysDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  p256dh: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  auth: string;
}

export class CreatePushSubscriptionDto {
  // The endpoint is a URL issued by the browser's own push service, and it
  // is the only field the server will ever send a request to. Validating it
  // as an https URL is the guard that stops this endpoint from being turned
  // into a way to make the backend call an arbitrary host (SSRF).
  @IsUrl({ protocols: ['https'], require_protocol: true })
  @MaxLength(2048)
  endpoint: string;

  @IsObject()
  @ValidateNested()
  @Type(() => PushKeysDto)
  keys: PushKeysDto;
}

export class DeletePushSubscriptionDto {
  @IsUrl({ protocols: ['https'], require_protocol: true })
  @MaxLength(2048)
  endpoint: string;
}

export class PushSubscriptionQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(512)
  userAgent?: string;
}
