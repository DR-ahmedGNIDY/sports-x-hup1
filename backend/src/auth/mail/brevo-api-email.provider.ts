import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailProvider } from './email-provider.interface';

const BREVO_SEND_ENDPOINT = 'https://api.brevo.com/v3/smtp/email';

// Brevo's own SMTP relay is unreachable from hosts that block outbound mail
// ports — Railway's trial plan blocks 25/465/587/2525, so every send from
// SmtpEmailProvider there dies on a TCP connection timeout well before it
// ever authenticates. This provider sends the identical message over
// ordinary HTTPS on 443 instead, which no host blocks.
const SEND_TIMEOUT_MS = 15_000;

/**
 * Real transactional email via Brevo's HTTP API rather than SMTP. Selected
 * with MAIL_PROVIDER=brevo, and interchangeable with [SmtpEmailProvider] —
 * both satisfy [EmailProvider], so MailService and AuthService are unaware
 * of which one is bound (see auth.module.ts).
 *
 * `SMTP_FROM` is reused verbatim as the sender so the two providers stay
 * configured the same way; it accepts either a bare address or the
 * `Name <address>` form, and Brevo requires whichever address it names to
 * be a verified sender on the account.
 */
@Injectable()
export class BrevoApiEmailProvider implements EmailProvider {
  private readonly logger = new Logger(BrevoApiEmailProvider.name);
  private readonly apiKey: string;
  private readonly sender: { email: string; name?: string };

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('BREVO_API_KEY') as string;
    this.sender = parseSender(config.get<string>('SMTP_FROM') as string);
  }

  async sendPasswordResetEmail({
    to,
    resetUrl,
  }: {
    to: string;
    resetUrl: string;
  }): Promise<void> {
    // Never logs `resetUrl` — it embeds the raw, single-use reset token
    // (CWE-532). Same rule as SmtpEmailProvider.
    const response = await fetch(BREVO_SEND_ENDPOINT, {
      method: 'POST',
      headers: {
        'api-key': this.apiKey,
        'content-type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify({
        sender: this.sender,
        to: [{ email: to }],
        subject: 'Reset your Sport X Hub password',
        textContent: `We received a request to reset your Sport X Hub password.\n\nReset it here (expires in 1 hour): ${resetUrl}\n\nIf you didn't request this, you can safely ignore this email.`,
        htmlContent: `<p>We received a request to reset your Sport X Hub password.</p><p><a href="${resetUrl}">Reset your password</a> (expires in 1 hour).</p><p>If you didn't request this, you can safely ignore this email.</p>`,
      }),
      signal: AbortSignal.timeout(SEND_TIMEOUT_MS),
    });

    if (!response.ok) {
      // Brevo answers a rejected send with a JSON {code, message} body that
      // names the actual cause — an unverified sender, a revoked key. That
      // wording is worth surfacing, and carries nothing secret; the body is
      // read defensively because an error response is not guaranteed to be
      // JSON at all.
      const detail = await response.text().catch(() => '');
      throw new Error(
        `Brevo API responded ${response.status}${detail ? `: ${detail}` : ''}`,
      );
    }
  }
}

/** Splits `Name <address>` into Brevo's sender shape; a bare address works too. */
function parseSender(from: string): { email: string; name?: string } {
  const match = /^\s*(.*?)\s*<\s*([^>]+?)\s*>\s*$/.exec(from);
  if (!match) return { email: from.trim() };
  const [, name, email] = match;
  return name ? { email, name } : { email };
}
