import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ContactService } from './contact.service';
import { CreateContactMessageDto } from './dto/create-contact-message.dto';

@Controller('contact')
export class ContactController {
  constructor(private readonly contactService: ContactService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  // Public, unauthenticated form — same spam/abuse-prone shape as the auth
  // endpoints, so it gets the same strict per-IP limit rather than the
  // API-wide default (see auth.controller.ts).
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  async submit(@Body() dto: CreateContactMessageDto) {
    await this.contactService.create(dto);
    return { success: true };
  }
}
