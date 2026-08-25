/**
 * Delivery seam for transactional email. `MailService` owns the business
 * logic (building the reset link, deciding what to log); an `EmailProvider`
 * only knows how to actually send a message. Swapping SMTP for a
 * transactional API (SES, SendGrid, Postmark, ...) means adding one more
 * class here — nothing in AuthService or MailService's calling code changes.
 */
export interface EmailProvider {
  sendPasswordResetEmail(params: {
    to: string;
    resetUrl: string;
  }): Promise<void>;
}

export const EMAIL_PROVIDER = Symbol('EMAIL_PROVIDER');
