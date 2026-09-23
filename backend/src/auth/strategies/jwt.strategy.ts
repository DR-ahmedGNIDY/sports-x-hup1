import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../../users/users.service';
import { UserStatus } from '../../users/schemas/user.schema';
import { JwtPayload } from '../decorators/current-user.decorator';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    private readonly usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // Joi validation (env.validation.ts) guarantees this is set and non-empty.
      secretOrKey: config.get<string>('JWT_SECRET') as string,
      // Explicitly pin the accepted signing algorithm rather than relying on
      // jsonwebtoken's default behavior — closes off any future library
      // change that might otherwise widen what a symmetric secret can
      // validate (CWE-347, OWASP ASVS 3.5/6.2 "algorithm confusion").
      algorithms: ['HS256'],
    });
  }

  // Whatever this returns becomes `request.user`. Checked against the live
  // user record (not just the token's signature) so an admin suspending a
  // user takes effect on their very next request, not just after their
  // short-lived access token happens to expire — the Phase 4 acceptance
  // criterion is "immediately loses access."
  async validate(payload: JwtPayload): Promise<JwtPayload> {
    const found = await this.usersService.findById(payload.sub);
    // A fixed-term suspension ends on its own: this is the hook that lets
    // the account come back the moment it is next used, with no cron job.
    const user = found
      ? await this.usersService.liftExpiredSuspension(found)
      : null;
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('This account has been suspended.');
    }
    // Read live rather than trusted from the token, so an admin granting or
    // revoking moderation is effective on the very next request.
    return { ...payload, isModerator: user.isModerator ?? false };
  }
}
