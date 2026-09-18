// What a club lets one of its coaches do on its behalf. Stored per
// membership, so the same coach can hold different grants at different
// clubs. Checked from the database on every request (never baked into the
// JWT), so a revoked grant stops working immediately.
//
// Deliberately absent, because only the club account itself may do them:
// managing coaches and their permissions, the club's login/deletion, and
// posting to the feed as the club.
export enum CoachPermission {
  /** Always held — the baseline of being on a club's staff. */
  VIEW_SQUAD = 'VIEW_SQUAD',
  VIEW_PLAYER_CONTACTS = 'VIEW_PLAYER_CONTACTS',
  MANAGE_CALENDAR = 'MANAGE_CALENDAR',
  MANAGE_LINEUP = 'MANAGE_LINEUP',
  INVITE_PLAYERS = 'INVITE_PLAYERS',
  CREATE_PLAYERS = 'CREATE_PLAYERS',
  MANAGE_CLUB_PLAYERS = 'MANAGE_CLUB_PLAYERS',
  EDIT_CLUB_PROFILE = 'EDIT_CLUB_PROFILE',
  REMOVE_MEMBERS = 'REMOVE_MEMBERS',
}

export const ALL_COACH_PERMISSIONS = Object.values(CoachPermission);

export const DEFAULT_COACH_PERMISSIONS = [CoachPermission.VIEW_SQUAD];

/** Normalises a grant: de-duplicated, and VIEW_SQUAD always present. */
export function normalizePermissions(
  permissions: CoachPermission[],
): CoachPermission[] {
  return ALL_COACH_PERMISSIONS.filter(
    (p) => p === CoachPermission.VIEW_SQUAD || permissions.includes(p),
  );
}
