import { Injectable } from '@nestjs/common';
import { ClubAccessService } from '../club-access/club-access.service';
import { ClubsService } from '../clubs/clubs.service';
import { CoachClubView } from './coaches.mapper';

// The "current clubs" line of a coach's CV, derived from live memberships
// rather than typed in, so it can never claim a club the coach has left.
@Injectable()
export class CoachClubsService {
  constructor(
    private readonly access: ClubAccessService,
    private readonly clubsService: ClubsService,
  ) {}

  async currentClubsFor(coachUserId: string): Promise<CoachClubView[]> {
    const memberships = await this.access.listActiveForCoach(coachUserId);
    if (memberships.length === 0) return [];

    const clubs = await this.clubsService.findManyByUserIds(
      memberships.map((m) => m.clubUserId.toString()),
    );
    const byUserId = new Map(clubs.map((c) => [c.userId.toString(), c]));
    return memberships.flatMap((membership) => {
      const club = byUserId.get(membership.clubUserId.toString());
      if (!club) return [];
      return [
        {
          id: club._id.toString(),
          name: club.name,
          logoUrl: club.logo?.secureUrl,
          publicCode: club.publicCode,
          joinedAt: membership.joinedAt,
        },
      ];
    });
  }
}
