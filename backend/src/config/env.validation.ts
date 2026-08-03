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
});
