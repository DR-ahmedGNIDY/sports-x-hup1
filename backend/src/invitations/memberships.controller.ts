import { Controller, Get, Param, Query } from '@nestjs/common';
import { ClubsService } from '../clubs/clubs.service';
import { PlayersService } from '../players/players.service';
import { ListMembersDto } from './dto/list-members.dto';
import { toClubMemberView, toPlayerClubView } from './memberships.mapper';
import { MembershipsService } from './memberships.service';

// The read side of memberships, addressed by *profile* id because that is
// what a public profile page has in hand. Both routes are unauthenticated,
// matching the pages they render on: GET /players/:id and GET /clubs/:id are
// already public, and neither route here discloses anything those two and
// GET /players don't already.
//
// Writes are deliberately absent. A membership is created only by accepting
// an invitation, and ending one is a product decision nothing in the current
// UI asks for — MembershipsService.end exists, but exposing it before there
// is a screen that means it would be inventing a rule (who may end it, and
// what the other party is told) with no caller to answer for it.
@Controller('memberships')
export class MembershipsController {
  constructor(
    private readonly memberships: MembershipsService,
    private readonly playersService: PlayersService,
    private readonly clubsService: ClubsService,
  ) {}

  // A club's current players. PUBLIC profiles only — belonging to a club is
  // not a way around a player's visibility setting — and the total counts
  // the same filtered set, so this can never report "5 of 8" and thereby
  // disclose the three it may not show.
  @Get('clubs/:clubId/players')
  async clubMembers(
    @Param('clubId') clubId: string,
    @Query() dto: ListMembersDto,
  ) {
    const clubProfile = await this.clubsService.findByIdOrThrow(clubId);
    const members = await this.memberships.listActiveForClubUnpaginated(
      clubProfile.userId.toString(),
    );
    if (members.length === 0) {
      return { items: [], page: dto.page ?? 1, pageSize: 20, total: 0 };
    }

    const joinedAtByUserId = new Map(
      members.map((m) => [m.playerUserId, m.joinedAt]),
    );
    const result = await this.playersService.findManyPublicByUserIds(
      members.map((m) => m.playerUserId),
      dto.page ?? 1,
    );
    return {
      items: result.items.map((profile) =>
        toClubMemberView(profile, joinedAtByUserId.get(profile.userId.toString())),
      ),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  // The club a player currently belongs to, or `null` — an absent membership
  // is the ordinary case, not an error, so this answers 200 with an empty
  // body rather than a 404 the profile page would have to treat as success.
  // The player itself must be public: a private profile has no public page
  // for this to appear on, and answering here would confirm the account
  // exists.
  @Get('players/:playerId/club')
  async playerClub(@Param('playerId') playerId: string) {
    const playerProfile =
      await this.playersService.findPublicByIdOrThrow(playerId);
    const membership = await this.memberships.findActiveForPlayer(
      playerProfile.userId.toString(),
    );
    if (!membership) return { membership: null };

    const clubProfile = await this.clubsService.findByUserId(
      membership.clubUserId.toString(),
    );
    return { membership: toPlayerClubView(membership, clubProfile) };
  }
}
