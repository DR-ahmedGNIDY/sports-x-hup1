import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  // CORS_ORIGINS is a comma-separated allowlist (env.validation.ts requires
  // it whenever NODE_ENV=production). Left empty, only in non-production,
  // this falls back to allowing any origin — convenient for local dev,
  // never silently allowed in a real deployment.
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
