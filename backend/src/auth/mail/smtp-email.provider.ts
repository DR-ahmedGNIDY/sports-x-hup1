import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { EmailProvider } from './email-provider.interface';

/**
 * Real transactional email via SMTP (Nodemailer). Used whenever
 * MAIL_PROVIDER=smtp — env.validation.ts requires this in production and
 * staging, so a real deployment can never silently fall back to the
 * no-op/console provider.
 */
@Injectable()
export class SmtpEmailProvider implements EmailProvider {
  private readonly logger = new Logger(SmtpEmailProvider.name);
  private readonly transporter: nodemailer.Transporter;
  private readonly from: string;

  constructor(config: ConfigService) {
    this.from = config.get<string>('SMTP_FROM') as string;
    this.transporter = nodemailer.createTransport({
      host: config.get<string>('SMTP_HOST'),
      port: config.get<number>('SMTP_PORT'),
      secure: config.get<boolean>('SMTP_SECURE'),
      auth: {
        user: config.get<string>('SMTP_USER'),
        pass: config.get<string>('SMTP_PASSWORD'),
      },
    });
  }

  async sendPasswordResetEmail({
    to,
    resetUrl,
  }: {
    to: string;
    resetUrl: string;
  }): Promise<void> {
    // Intentionally never logs `resetUrl` (it embeds the raw, single-use
    // reset token) — only the fact that a send was attempted and its
    // outcome (CWE-532: sensitive data in log files).
    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject: 'Reset your Sport X Hub password',
        text: `We received a request to reset your Sport X Hub password.\n\nReset it here (expires in 1 hour): ${resetUrl}\n\nIf you didn't request this, you can safely ignore this email.`,
        html: `<p>We received a request to reset your Sport X Hub password.</p><p><a href="${resetUrl}">Reset your password</a> (expires in 1 hour).</p><p>If you didn't request this, you can safely ignore this email.</p>`,
      });
    } catch (error) {
      this.logger.error(
        `Failed to send password reset email: ${(error as Error).message}`,
      );
      throw error;
    }
  }
}
