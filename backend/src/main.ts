import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  app.enableCors();
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
