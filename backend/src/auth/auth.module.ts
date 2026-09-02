import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { PassportModule } from '@nestjs/passport';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { BrevoApiEmailProvider } from './mail/brevo-api-email.provider';
import { ConsoleEmailProvider } from './mail/console-email.provider';
import { EMAIL_PROVIDER } from './mail/email-provider.interface';
import { MailService } from './mail/mail.service';
import { SmtpEmailProvider } from './mail/smtp-email.provider';
import {
  PasswordResetToken,
  PasswordResetTokenSchema,
} from './schemas/password-reset-token.schema';
import {
  RefreshToken,
  RefreshTokenSchema,
} from './schemas/refresh-token.schema';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    UsersModule,
    PassportModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
      }),
    }),
    MongooseModule.forFeature([
      { name: RefreshToken.name, schema: RefreshTokenSchema },
      { name: PasswordResetToken.name, schema: PasswordResetTokenSchema },
    ]),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    MailService,
    JwtStrategy,
    SmtpEmailProvider,
    BrevoApiEmailProvider,
    ConsoleEmailProvider,
    {
      provide: EMAIL_PROVIDER,
      inject: [
        ConfigService,
        SmtpEmailProvider,
        BrevoApiEmailProvider,
        ConsoleEmailProvider,
      ],
      useFactory: (
        config: ConfigService,
        smtp: SmtpEmailProvider,
        brevo: BrevoApiEmailProvider,
        console: ConsoleEmailProvider,
      ) => {
        // env.validation.ts already restricts this to 'smtp' | 'brevo' in
        // production/staging, so `console` is only ever reachable in
        // development/test — the same guarantee as before 'brevo' existed.
        switch (config.get<string>('MAIL_PROVIDER')) {
          case 'smtp':
            return smtp;
          case 'brevo':
            return brevo;
          default:
            return console;
        }
      },
    },
  ],
})
export class AuthModule {}
