import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { PassportModule } from '@nestjs/passport';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
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
    ConsoleEmailProvider,
    {
      provide: EMAIL_PROVIDER,
      inject: [ConfigService, SmtpEmailProvider, ConsoleEmailProvider],
      useFactory: (
        config: ConfigService,
        smtp: SmtpEmailProvider,
        console: ConsoleEmailProvider,
      ) => (config.get<string>('MAIL_PROVIDER') === 'smtp' ? smtp : console),
    },
  ],
})
export class AuthModule {}
