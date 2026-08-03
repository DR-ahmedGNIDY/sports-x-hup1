import * as Joi from 'joi';

/**
 * Phase 0 only validates what Phase 0 itself needs to boot (MONGODB_URI,
 * with a local dev fallback). JWT/Cloudinary keys are documented here and
 * in .env.example so they exist ahead of time, but are intentionally not
 * required yet — nothing in the codebase consumes them until Phase 1/2,
 * which will tighten this schema when they do.
 */
export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'staging', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),

  MONGODB_URI: Joi.string()
    .empty('')
    .default('mongodb://127.0.0.1:27017/sportxhub'),

  JWT_SECRET: Joi.string().allow('').default(''),
  JWT_REFRESH_SECRET: Joi.string().allow('').default(''),

  CLOUDINARY_CLOUD_NAME: Joi.string().allow('').default(''),
  CLOUDINARY_API_KEY: Joi.string().allow('').default(''),
  CLOUDINARY_API_SECRET: Joi.string().allow('').default(''),
});
