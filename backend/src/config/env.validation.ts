import * as Joi from 'joi';

/**
 * Validates only what the codebase actually consumes at each phase.
 * MONGODB_URI has a local dev fallback (Phase 0). JWT_SECRET signs access
 * tokens and JWT_REFRESH_SECRET keys the HMAC used to hash opaque
 * refresh/reset tokens (Phase 1, AuthService) — both are now required, non-
 * placeholder values. CLOUDINARY_* stay optional until Phase 2 wires
 * Cloudinary uploads; this schema will tighten again then.
 */
export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'staging', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),

  MONGODB_URI: Joi.string()
    .empty('')
    .default('mongodb://127.0.0.1:27017/sportxhub'),

  // 32+ chars (256 bits) is the floor for HS256; .env.example recommends
  // generating these with `openssl rand -hex 64`, well above this minimum.
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),

  CLOUDINARY_CLOUD_NAME: Joi.string().allow('').default(''),
  CLOUDINARY_API_KEY: Joi.string().allow('').default(''),
  CLOUDINARY_API_SECRET: Joi.string().allow('').default(''),

  // Comma-separated list of allowed frontend origins (e.g.
  // "https://app.sportxhub.com,https://sportxhub.com"). Optional in
  // development/test — an empty value there falls back to reflecting the
  // request origin, which is a convenience for local dev only. Both
  // production AND staging (a real, internet-reachable deployment) must
  // set this explicitly; a wildcard is rejected outright since
  // `credentials: true` is always on and CORS forbids combining the two
  // safely (CWE-346, OWASP ASVS 14.5).
  CORS_ORIGINS: Joi.string()
    .allow('')
    .default('')
    .when('NODE_ENV', {
      is: Joi.valid('production', 'staging'),
      then: Joi.string()
        .min(1)
        .required()
        .custom((value: string, helpers) => {
          const origins = value.split(',').map((origin) => origin.trim());
          if (origins.includes('*')) {
            return helpers.error('any.invalid');
          }
          return value;
        }, 'no wildcard origin')
        .messages({
          'any.invalid':
            'CORS_ORIGINS cannot be "*" in production/staging — list explicit origins instead.',
        }),
    }),

  // Password-reset email provider (Phase 0.5). "console" only logs that an
  // email would have been sent (no token, see mail.service.ts) and is
  // rejected outside development/test — a real deployment must be able to
  // actually deliver the reset email, not silently drop it.
  // NOTE: the enum restriction lives entirely inside the `when()` branches
  // (not also chained on the base schema) — Joi's `.when()` does not fully
  // replace a base `.valid(...)` list with the matched branch's list, so
  // combining both would let a value the `then` branch was meant to reject
  // (e.g. "console" in production) slip through as still-valid-by-base.
  MAIL_PROVIDER: Joi.string()
    .default('console')
    .when('NODE_ENV', {
      is: Joi.valid('production', 'staging'),
      then: Joi.string().valid('smtp', 'brevo').required().messages({
        'any.only':
          'MAIL_PROVIDER must be "smtp" or "brevo" in production/staging — "console" never sends a real email.',
      }),
      otherwise: Joi.string().valid('smtp', 'brevo', 'console'),
    }),

  // Brevo's HTTP API key, required only for MAIL_PROVIDER=brevo. That
  // provider exists because hosts commonly block outbound SMTP ports —
  // Railway's trial plan blocks 25/465/587/2525 alike, so SMTP there fails
  // with a TCP connection timeout no credential change can fix. Sending
  // over HTTPS on 443 sidesteps the block entirely.
  BREVO_API_KEY: Joi.string()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: 'brevo',
      then: Joi.string().min(1).required(),
    }),

  SMTP_HOST: Joi.string()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: 'smtp',
      then: Joi.string().min(1).required(),
    }),
  SMTP_PORT: Joi.number().default(587),
  SMTP_SECURE: Joi.boolean().default(false),
  SMTP_USER: Joi.string()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: 'smtp',
      then: Joi.string().min(1).required(),
    }),
  SMTP_PASSWORD: Joi.string()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: 'smtp',
      then: Joi.string().min(1).required(),
    }),
  // Both real providers send "from" this address — SmtpEmailProvider hands
  // it to nodemailer, BrevoApiEmailProvider parses it into Brevo's sender
  // object — so it is required for either, not just smtp.
  SMTP_FROM: Joi.string()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: Joi.valid('smtp', 'brevo'),
      then: Joi.string().min(1).required(),
    }),

  // Base URL used to build the password-reset link embedded in the email.
  // Required whenever an email is actually sent (smtp or brevo); the
  // console provider only logs a placeholder and doesn't need it.
  FRONTEND_URL: Joi.string()
    .uri()
    .allow('')
    .default('')
    .when('MAIL_PROVIDER', {
      is: Joi.valid('smtp', 'brevo'),
      then: Joi.string().uri().required(),
    }),
});
