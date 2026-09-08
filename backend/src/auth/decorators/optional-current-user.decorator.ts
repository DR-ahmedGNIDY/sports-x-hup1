import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtPayload } from './current-user.decorator';

interface RequestWithOptionalUser {
  user?: JwtPayload;
}

// The counterpart to @CurrentUser for routes behind OptionalJwtAuthGuard,
// where an absent user is the normal case rather than a bug. Typed as
// possibly-undefined so callers are made to handle the guest path.
export const OptionalCurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtPayload | undefined => {
    const request = ctx.switchToHttp().getRequest<RequestWithOptionalUser>();
    return request.user;
  },
);
