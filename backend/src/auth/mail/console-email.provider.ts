import { Injectable, Logger } from '@nestjs/common';
import { EmailProvider } from './email-provider.interface';

/**
 * Dev/test-only stand-in for a real mail provider. env.validation.ts
 * rejects MAIL_PROVIDER=console whenever NODE_ENV is production or
 * staging, so this class can only ever run in development/test — printing
 * the reset link here is what makes the forgot/reset-password flow locally
 * testable end-to-end without real SMTP infrastructure, and is scoped to
 * this one file rather than general application logging.
 */
@Injectable()
export class ConsoleEmailProvider implements EmailProvider {
  private readonly logger = new Logger(ConsoleEmailProvider.name);

  async sendPasswordResetEmail({
    to,
    resetUrl,
  }: {
    to: string;
    resetUrl: string;
  }): Promise<void> {
    this.logger.log(
      `[DEV ONLY — no MAIL_PROVIDER=smtp configured] Password reset link for ${to}: ${resetUrl}`,
    );
  }
}
