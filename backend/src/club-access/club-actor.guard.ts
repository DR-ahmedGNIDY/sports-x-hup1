import {
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtPayload } from '../auth/decorators/current-user.decorator';
import { UserRole } from '../users/schemas/user.schema';
import { ClubAccessService, ClubActor } from './club-access.service';
import { CoachPermission } from './coach-permission.enum';

/** The header a coach sends to say which of their clubs they act for. */
export const CLUB_CONTEXT_HEADER = 'x-club-id';

const CLUB_PERMISSION_KEY = 'clubPermission';

/**
 * What a coach must hold to use this route. A club account always passes.
 * Without it the route still resolves the actor, and a coach needs no more
 * than membership (the implicit VIEW_SQUAD).
 */
export const ClubPermission = (permission: CoachPermission) =>
  SetMetadata(CLUB_PERMISSION_KEY, permission);

interface ClubActorRequest {
  user: JwtPayload;
  headers: Record<string, string | string[] | undefined>;
  clubActor?: ClubActor;
}

/** The actor on routes that also admit non-club roles; undefined for those. */
export const OptionalClubActorParam = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): ClubActor | undefined =>
    ctx.switchToHttp().getRequest<ClubActorRequest>().clubActor,
);

/**
 * Resolves who is acting for which club and puts it on the request for
 * `@ClubActorParam()`. Must run after JwtAuthGuard and RolesGuard.
 */
@Injectable()
export class ClubActorGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly access: ClubAccessService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<
      CoachPermission | undefined
    >(CLUB_PERMISSION_KEY, [context.getHandler(), context.getClass()]);
    const request = context.switchToHttp().getRequest<ClubActorRequest>();
    // Only a club or a coach acts for a club. Anyone else a route admits
    // (e.g. a player reading their own event) passes through untouched —
    // RolesGuard has already decided whether they may be here at all.
    if (
      request.user.role !== UserRole.CLUB &&
      request.user.role !== UserRole.COACH
    ) {
      return true;
    }
    const header = request.headers[CLUB_CONTEXT_HEADER];
    request.clubActor = await this.access.resolve(
      request.user,
      Array.isArray(header) ? header[0] : header,
      required,
    );
    return true;
  }
}

export const ClubActorParam = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): ClubActor => {
    const actor = ctx.switchToHttp().getRequest<ClubActorRequest>().clubActor;
    if (!actor) {
      // A route used the decorator without the guard — a wiring mistake,
      // never a request problem.
      throw new Error('ClubActorParam used without ClubActorGuard.');
    }
    return actor;
  },
);
