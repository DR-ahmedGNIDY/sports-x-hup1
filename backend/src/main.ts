import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const nodeEnv = config.get<string>('NODE_ENV') ?? 'development';
  const isProduction = nodeEnv === 'production';

  // Security headers (OWASP ASVS 14.4, CWE-693). This is a JSON API, not an
  // HTML-serving app — Flutter Web is served separately by nginx — so the
  // default CSP (meant to restrict inline scripts/styles on rendered pages)
  // is unnecessary here and disabled to avoid constraining an origin it
  // doesn't apply to. HSTS is only sent in production, where the API is
  // actually served over HTTPS; forcing it in development would make
  // `http://localhost` unusable in browsers that cache the header.
  app.use(
    helmet({
      contentSecurityPolicy: false,
      hsts: isProduction
        ? { maxAge: 15552000, includeSubDomains: true }
        : false,
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  // CORS_ORIGINS is a comma-separated allowlist. env.validation.ts requires
  // a non-empty, non-wildcard value whenever NODE_ENV is production or
  // staging — so reaching the empty-list branch here is only possible in
  // development/test, where reflecting the request origin is a convenience,
  // never a silent production/staging fallback.
  const corsOrigins = (config.get<string>('CORS_ORIGINS') ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  app.enableCors({
    origin: corsOrigins.length > 0 ? corsOrigins : true,
    credentials: true,
  });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const port = config.get<number>('PORT') ?? 3000;
  await app.listen(port);
}

bootstrap().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(
    'Failed to start Sport X Hub API — is MONGODB_URI reachable? See backend/.env.example.',
    error,
  );
  process.exit(1);
});
