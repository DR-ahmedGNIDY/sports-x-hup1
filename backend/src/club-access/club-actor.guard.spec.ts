import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../users/schemas/user.schema';
import { ClubAccessService } from './club-access.service';
import { ClubActorGuard } from './club-actor.guard';
import { CoachPermission } from './coach-permission.enum';

describe('ClubActorGuard', () => {
  function run(
    role: UserRole,
    headers: Record<string, string> = {},
    required?: CoachPermission,
  ) {
    const request: Record<string, unknown> = {
      user: { sub: 'u1', role },
      headers,
    };
    const context = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => undefined,
      getClass: () => undefined,
    } as unknown as ExecutionContext;
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue(required),
    } as unknown as Reflector;
    const access = {
      resolve: jest.fn().mockResolvedValue({ clubUserId: 'club-1' }),
    };
    const guard = new ClubActorGuard(
      reflector,
      access as unknown as ClubAccessService,
    );
    return { guard, context, request, access };
  }

  it('lets a player through without resolving any club', async () => {
    const { guard, context, request, access } = run(UserRole.PLAYER);

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(access.resolve).not.toHaveBeenCalled();
    expect(request.clubActor).toBeUndefined();
  });

  it('resolves a coach against the X-Club-Id header and the route permission', async () => {
    const { guard, context, request, access } = run(
      UserRole.COACH,
      { 'x-club-id': 'profile-9' },
      CoachPermission.MANAGE_LINEUP,
    );

    await guard.canActivate(context);

    expect(access.resolve).toHaveBeenCalledWith(
      { sub: 'u1', role: UserRole.COACH },
      'profile-9',
      CoachPermission.MANAGE_LINEUP,
    );
    expect(request.clubActor).toEqual({ clubUserId: 'club-1' });
  });

  it('propagates a refusal from the resolver', async () => {
    const { guard, context, access } = run(UserRole.COACH);
    access.resolve.mockRejectedValue(new Error('403'));

    await expect(guard.canActivate(context)).rejects.toThrow('403');
  });
});
