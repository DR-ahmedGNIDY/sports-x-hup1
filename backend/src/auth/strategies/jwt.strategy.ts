import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { JwtPayload } from '../decorators/current-user.decorator';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // Joi validation (env.validation.ts) guarantees this is set and non-empty.
      secretOrKey: config.get<string>('JWT_SECRET') as string,
    });
  }

  // Whatever this returns becomes `request.user`.
  validate(payload: JwtPayload): JwtPayload {
    return payload;
  }
}
