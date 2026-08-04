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
    });
  }

  // Whatever this returns becomes `request.user`. Checked against the live
  // user record (not just the token's signature) so an admin suspending a
  // user takes effect on their very next request, not just after their
  // short-lived access token happens to expire — the Phase 4 acceptance
  // criterion is "immediately loses access."
  async validate(payload: JwtPayload): Promise<JwtPayload> {
    const user = await this.usersService.findById(payload.sub);
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('This account has been suspended.');
    }
    return payload;
  }
}
