import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EMAIL_PROVIDER, EmailProvider } from './email-provider.interface';

/**
 * Business logic for password-reset email: builds the reset link and
 * decides what's safe to log. Delivery is delegated to whichever
 * `EmailProvider` is bound for MAIL_PROVIDER (see mail.module.ts) — this
 * class never touches SMTP/nodemailer directly, so swapping providers
 * never requires touching AuthService or this file's callers.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(
    @Inject(EMAIL_PROVIDER) private readonly provider: EmailProvider,
    private readonly config: ConfigService,
  ) {}

  async sendPasswordResetEmail(
    email: string,
    resetToken: string,
    correlationId: string,
  ): Promise<void> {
    const frontendUrl = this.config.get<string>('FRONTEND_URL') ?? '';
    const resetUrl = `${frontendUrl}/reset-password?token=${encodeURIComponent(resetToken)}`;

    try {
      await this.provider.sendPasswordResetEmail({ to: email, resetUrl });
      // Never log `resetToken` or `resetUrl` here or in any provider impl —
      // both carry the raw, single-use credential (CWE-532). `correlationId`
      // is the persisted reset-token document's own Mongo _id: safe to log
      // (not reversible to the token, not sensitive) and enough for support
      // to correlate "was an email attempted for this request" without ever
      // touching the secret itself.
      this.logger.log(
        `Password reset email dispatched (correlationId=${correlationId}).`,
      );
    } catch {
      this.logger.error(
        `Password reset email failed to send (correlationId=${correlationId}).`,
      );
    }
  }
}
