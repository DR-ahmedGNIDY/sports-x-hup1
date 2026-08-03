import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * MVP has no transactional email provider wired up (none is part of the
 * approved stack). In development/test this logs the reset link so the
 * forgot/reset-password flow is fully exercisable end-to-end without one.
 * Swap the body of `sendPasswordResetEmail` for a real provider (e.g.
 * Nodemailer + SMTP, or a transactional email API) when one is chosen —
 * every caller already goes through this single seam.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly config: ConfigService) {}

  sendPasswordResetEmail(email: string, resetToken: string): void {
    const isProduction = this.config.get<string>('NODE_ENV') === 'production';
    if (isProduction) {
      this.logger.warn(
        `No email provider configured — password reset email to ${email} was NOT sent.`,
      );
      return;
    }

    this.logger.log(
      `[DEV] Password reset requested for ${email}. Reset token: ${resetToken}`,
    );
  }
}
