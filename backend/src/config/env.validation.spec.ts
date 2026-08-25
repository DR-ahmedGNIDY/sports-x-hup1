import { envValidationSchema } from './env.validation';

const REQUIRED_SECRETS = {
  JWT_SECRET: 'a'.repeat(32),
  JWT_REFRESH_SECRET: 'b'.repeat(32),
};

function validate(env: Record<string, string>) {
  return envValidationSchema.validate(
    { ...REQUIRED_SECRETS, ...env },
    { abortEarly: false },
  );
}

describe('envValidationSchema — CORS_ORIGINS', () => {
  it('allows an empty CORS_ORIGINS in development', () => {
    const { error } = validate({ NODE_ENV: 'development' });
    expect(error).toBeUndefined();
  });

  it('rejects an empty CORS_ORIGINS in production', () => {
    const { error } = validate({ NODE_ENV: 'production' });
    expect(error?.message).toMatch(/CORS_ORIGINS/);
  });

  it('rejects an empty CORS_ORIGINS in staging', () => {
    const { error } = validate({ NODE_ENV: 'staging' });
    expect(error?.message).toMatch(/CORS_ORIGINS/);
  });

  it('rejects a wildcard CORS_ORIGINS in production', () => {
    const { error } = validate({ NODE_ENV: 'production', CORS_ORIGINS: '*' });
    expect(error?.message).toMatch(/cannot be "\*"/);
  });

  it('rejects a wildcard CORS_ORIGINS in staging', () => {
    const { error } = validate({ NODE_ENV: 'staging', CORS_ORIGINS: '*' });
    expect(error?.message).toMatch(/cannot be "\*"/);
  });

  it('accepts explicit origins in production', () => {
    const { error } = validate({
      NODE_ENV: 'production',
      CORS_ORIGINS: 'https://app.sportxhub.com,https://sportxhub.com',
      MAIL_PROVIDER: 'smtp',
      SMTP_HOST: 'smtp.example.com',
      SMTP_USER: 'user',
      SMTP_PASSWORD: 'pass',
      SMTP_FROM: 'no-reply@sportxhub.com',
      FRONTEND_URL: 'https://app.sportxhub.com',
    });
    expect(error).toBeUndefined();
  });
});

describe('envValidationSchema — MAIL_PROVIDER', () => {
  it('defaults to "console" in development', () => {
    const { value, error } = validate({ NODE_ENV: 'development' });
    expect(error).toBeUndefined();
    expect(value.MAIL_PROVIDER).toBe('console');
  });

  it('rejects MAIL_PROVIDER=console in production', () => {
    const { error } = validate({
      NODE_ENV: 'production',
      CORS_ORIGINS: 'https://app.sportxhub.com',
      MAIL_PROVIDER: 'console',
    });
    expect(error?.message).toMatch(/MAIL_PROVIDER/);
  });

  it('requires SMTP_* and FRONTEND_URL when MAIL_PROVIDER=smtp', () => {
    const { error } = validate({
      NODE_ENV: 'development',
      MAIL_PROVIDER: 'smtp',
    });
    expect(error?.message).toMatch(/SMTP_HOST/);
  });

  it('passes when MAIL_PROVIDER=smtp and all SMTP_*/FRONTEND_URL are set', () => {
    const { error } = validate({
      NODE_ENV: 'staging',
      CORS_ORIGINS: 'https://staging.sportxhub.com',
      MAIL_PROVIDER: 'smtp',
      SMTP_HOST: 'smtp.example.com',
      SMTP_USER: 'user',
      SMTP_PASSWORD: 'pass',
      SMTP_FROM: 'no-reply@sportxhub.com',
      FRONTEND_URL: 'https://staging.sportxhub.com',
    });
    expect(error).toBeUndefined();
  });
});
