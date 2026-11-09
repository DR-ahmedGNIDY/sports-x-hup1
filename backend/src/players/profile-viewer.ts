import { JwtPayload } from '../auth/decorators/current-user.decorator';
import { ClubAccessService } from '../club-access/club-access.service';
import { UserRole } from '../users/schemas/user.schema';

/** Who is looking at a player's profile, for PRIVATE-profile checks. */
export interface ProfileViewer {
  userId?: string;
  clubUserId?: string;
}

// Turns an optional sign-in into a viewer for
// PlayersService.findViewableByIdOrThrow. A club acts for itself; a coach
// for the club named in X-Club-Id, and one not on that club's staff is just
// an ordinary signed-in viewer — this never throws.
export async function resolveProfileViewer(
  clubAccess: ClubAccessService,
  user: JwtPayload | undefined,
  clubHeader: string | undefined,
): Promise<ProfileViewer> {
  if (!user) return {};
  let clubUserId: string | undefined;
  if (user.role === UserRole.CLUB || user.role === UserRole.COACH) {
    clubUserId = await clubAccess
      .resolve(user, clubHeader)
      .then((actor) => actor.clubUserId)
      .catch(() => undefined);
  }
  return { userId: user.sub, clubUserId };
}
