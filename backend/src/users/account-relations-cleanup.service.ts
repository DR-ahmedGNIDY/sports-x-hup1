import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CalendarEvent } from '../calendar-events/schemas/calendar-event.schema';
import { ClubManagedPlayer } from '../club-players/schemas/club-managed-player.schema';
import { ClubCoachInvitation } from '../coach-invitations/schemas/club-coach-invitation.schema';
import { ClubMembership } from '../invitations/schemas/club-membership.schema';
import { ClubPlayerInvitation } from '../invitations/schemas/club-player-invitation.schema';
import { SavedPlayer } from '../saved-players/schemas/saved-player.schema';
import { StoreOrder } from '../store/schemas/order.schema';

// The part of account deletion that lives between two accounts rather than
// inside one: invitations, memberships, bookmarks, a club's calendar, store
// orders. Works on the models directly (registered in UsersModule, the same
// pattern PlayersModule uses for SavedPlayer) because the modules that own
// these — InvitationsModule, ClubPlayersModule, CalendarEventsModule… —
// either import UsersModule themselves or sit above it, so importing them
// here would be a circular module dependency.
@Injectable()
export class AccountRelationsCleanupService {
  constructor(
    @InjectModel(ClubPlayerInvitation.name)
    private readonly playerInvitationModel: Model<ClubPlayerInvitation>,
    @InjectModel(ClubMembership.name)
    private readonly clubMembershipModel: Model<ClubMembership>,
    @InjectModel(ClubCoachInvitation.name)
    private readonly coachInvitationModel: Model<ClubCoachInvitation>,
    @InjectModel(ClubManagedPlayer.name)
    private readonly managedPlayerModel: Model<ClubManagedPlayer>,
    @InjectModel(SavedPlayer.name)
    private readonly savedPlayerModel: Model<SavedPlayer>,
    @InjectModel(CalendarEvent.name)
    private readonly calendarEventModel: Model<CalendarEvent>,
    @InjectModel(StoreOrder.name)
    private readonly orderModel: Model<StoreOrder>,
  ) {}

  /**
   * Deletes every relationship [userId] is a party to, on either side.
   * [playerProfileId] is the user's PlayerProfile id when they have one —
   * calendar rosters reference the profile, not the user — and must be
   * looked up before the profile itself is deleted.
   *
   * Returns the ids of the deleted invitations and calendar events, so the
   * caller can clear notifications (to anyone) that point at them.
   */
  async deleteAllForUser(
    userId: string,
    playerProfileId?: Types.ObjectId,
  ): Promise<Types.ObjectId[]> {
    const id = new Types.ObjectId(userId);

    const playerInvitationFilter = {
      $or: [{ clubUserId: id }, { playerUserId: id }],
    };
    const coachInvitationFilter = {
      $or: [{ clubUserId: id }, { coachUserId: id }],
    };
    // Only a club owns events; for anyone else this matches nothing.
    const ownEventsFilter = { clubUserId: id };

    const [playerInvitations, coachInvitations, ownEvents] = await Promise.all(
      [
        this.playerInvitationModel.find(playerInvitationFilter, { _id: 1 }),
        this.coachInvitationModel.find(coachInvitationFilter, { _id: 1 }),
        this.calendarEventModel.find(ownEventsFilter, { _id: 1 }),
      ],
    );

    await Promise.all([
      this.playerInvitationModel.deleteMany(playerInvitationFilter),
      this.coachInvitationModel.deleteMany(coachInvitationFilter),
      this.calendarEventModel.deleteMany(ownEventsFilter),
      this.clubMembershipModel.deleteMany({
        $or: [{ clubUserId: id }, { playerUserId: id }],
      }),
      // As the managed player: the ownership row goes with the account. As
      // the club: the players it created keep their own accounts (they are
      // real people who can still sign in) and simply stop being managed.
      this.managedPlayerModel.deleteMany({
        $or: [{ userId: id }, { clubId: id }],
      }),
      // A club's own bookmarks. Bookmarks *of* a player are removed by
      // PlayersService with the profile.
      this.savedPlayerModel.deleteMany({ clubUserId: id }),
      // A player on other clubs' rosters and match stats.
      ...(playerProfileId
        ? [
            this.calendarEventModel.updateMany(
              {
                $or: [
                  { 'participants.playerId': playerProfileId },
                  { 'matchStats.playerId': playerProfileId },
                ],
              },
              {
                $pull: {
                  participants: { playerId: playerProfileId },
                  matchStats: { playerId: playerProfileId },
                },
              },
            ),
          ]
        : []),
      // Orders are the merchant's sales records (what was sold, to which
      // address, for how much), so they are kept — but no longer tied to
      // the account, exactly like a guest checkout.
      this.orderModel.updateMany({ userId: id }, { $unset: { userId: 1 } }),
    ]);

    return [...playerInvitations, ...coachInvitations, ...ownEvents].map(
      (doc) => doc._id,
    );
  }
}
