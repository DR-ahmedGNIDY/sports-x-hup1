import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../users/schemas/user.schema';
import { RolesGuard } from './roles.guard';

describe('RolesGuard', () => {
  function buildContext(role: UserRole): ExecutionContext {
    return {
      switchToHttp: () => ({ getRequest: () => ({ user: { role } }) }),
      getHandler: () => undefined,
      getClass: () => undefined,
    } as unknown as ExecutionContext;
  }

  it('allows the request through when no @Roles() metadata is set', () => {
    const reflector = {
      getAllAndOverride: () => undefined,
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);

    expect(guard.canActivate(buildContext(UserRole.PLAYER))).toBe(true);
  });

  it('allows a matching role', () => {
    const reflector = {
      getAllAndOverride: () => [UserRole.CLUB],
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);

    expect(guard.canActivate(buildContext(UserRole.CLUB))).toBe(true);
  });

  it('rejects a non-matching role', () => {
    const reflector = {
      getAllAndOverride: () => [UserRole.CLUB],
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);

    expect(() => guard.canActivate(buildContext(UserRole.PLAYER))).toThrow(
      ForbiddenException,
    );
  });
});
