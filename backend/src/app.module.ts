import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
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
    HealthModule,
    UsersModule,
    AuthModule,
    SportsModule,
    CountriesModule,
    PlayersModule,
    ClubsModule,
    SavedPlayersModule,
    AdminModule,
  ],
})
export class AppModule {}
