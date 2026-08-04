import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcryptjs';
import { randomBytes, createHmac } from 'node:crypto';
import { Model } from 'mongoose';
import { UsersService } from '../users/users.service';
import { toPublicUser } from '../users/users.mapper';
import { UserRole, UserStatus } from '../users/schemas/user.schema';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { MailService } from './mail/mail.service';
import { PasswordResetToken } from './schemas/password-reset-token.schema';
import { RefreshToken } from './schemas/refresh-token.schema';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hour

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: ReturnType<typeof toPublicUser>;
}

function generateOpaqueToken(): string {
  return randomBytes(48).toString('hex');
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
    private readonly config: ConfigService,
    @InjectModel(RefreshToken.name)
    private readonly refreshTokenModel: Model<RefreshToken>,
    @InjectModel(PasswordResetToken.name)
    private readonly passwordResetTokenModel: Model<PasswordResetToken>,
  ) {}

  // Keyed hash (HMAC) rather than plain SHA-256: opaque refresh/reset tokens
  // are stored only as this hash, so a database read alone can never yield
  // a usable token without also knowing JWT_REFRESH_SECRET.
  private hashToken(token: string): string {
    return createHmac(
      'sha256',
      this.config.get<string>('JWT_REFRESH_SECRET') ?? '',
    )
      .update(token)
      .digest('hex');
  }

  async register(dto: RegisterDto): Promise<AuthTokens> {
    const user = await this.usersService.createPlayerOrClub(
      dto.email,
      dto.password,
      dto.role as UserRole.PLAYER | UserRole.CLUB,
    );
    return this.issueTokens(user.id, user.email, user.role, user);
  }

  async login(dto: LoginDto): Promise<AuthTokens> {
    const user = await this.usersService.findByEmail(dto.email);
    const matches = user
      ? await bcrypt.compare(dto.password, user.passwordHash)
      : false;
    if (!user || !matches) {
      throw new UnauthorizedException('Invalid email or password.');
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('This account has been suspended.');
    }
    return this.issueTokens(user.id, user.email, user.role, user);
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const tokenHash = this.hashToken(refreshToken);
    const stored = await this.refreshTokenModel.findOne({
      tokenHash,
      expiresAt: { $gt: new Date() },
    });
    if (!stored) {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }

    const user = await this.usersService.findByIdOrThrow(
      stored.userId.toString(),
    );
    await this.refreshTokenModel.deleteOne({ _id: stored._id }); // rotate on use
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('This account has been suspended.');
    }
    return this.issueTokens(user.id, user.email, user.role, user);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.refreshTokenModel.deleteOne({
      tokenHash: this.hashToken(refreshToken),
    });
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Same response regardless of whether the email exists, to avoid
      // leaking which addresses are registered.
      return;
    }

    const rawToken = generateOpaqueToken();
    await this.passwordResetTokenModel.create({
      userId: user._id,
      tokenHash: this.hashToken(rawToken),
      expiresAt: new Date(Date.now() + RESET_TOKEN_TTL_MS),
    });

    this.mailService.sendPasswordResetEmail(user.email, rawToken);
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const tokenHash = this.hashToken(token);
    const stored = await this.passwordResetTokenModel.findOne({
      tokenHash,
      expiresAt: { $gt: new Date() },
    });
    if (!stored) {
      throw new BadRequestException('Invalid or expired reset token.');
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.usersService.setPasswordHash(
      stored.userId.toString(),
      passwordHash,
    );

    // A password reset invalidates every existing session and any other
    // pending reset requests for this account.
    await Promise.all([
      this.passwordResetTokenModel.deleteMany({ userId: stored.userId }),
      this.refreshTokenModel.deleteMany({ userId: stored.userId }),
    ]);
  }

  private async issueTokens(
    userId: string,
    email: string,
    role: string,
    userDocument: Parameters<typeof toPublicUser>[0],
  ): Promise<AuthTokens> {
    const accessToken = this.jwtService.sign(
      { sub: userId, email, role },
      { expiresIn: ACCESS_TOKEN_TTL },
    );

    const refreshTokenRaw = generateOpaqueToken();
    await this.refreshTokenModel.create({
      userId,
      tokenHash: this.hashToken(refreshTokenRaw),
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_MS),
    });

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      user: toPublicUser(userDocument),
    };
  }
}
