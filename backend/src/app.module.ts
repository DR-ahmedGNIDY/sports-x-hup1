import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { envValidationSchema } from './config/env.validation';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SportsModule } from './sports/sports.module';
import { CountriesModule } from './countries/countries.module';
import { PlayersModule } from './players/players.module';
import { ClubsModule } from './clubs/clubs.module';
import { SavedPlayersModule } from './saved-players/saved-players.module';
import { AdminModule } from './admin/admin.module';
import { ContactModule } from './contact/contact.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: envValidationSchema,
    }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.get<string>('MONGODB_URI'),
        serverSelectionTimeoutMS: 3000,
        retryAttempts: 3,
        retryDelay: 2000,
      }),
    }),
    // API-wide default; auth's most sensitive endpoints (login, register,
    // refresh, forgot-password) additionally apply a much stricter
    // @Throttle() override — see auth.controller.ts.
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 100 }]),
    HealthModule,
    UsersModule,
    AuthModule,
    SportsModule,
    CountriesModule,
    PlayersModule,
    ClubsModule,
    SavedPlayersModule,
    AdminModule,
    ContactModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
