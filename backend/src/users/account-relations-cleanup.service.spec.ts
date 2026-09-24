import { Types } from 'mongoose';
import { AccountRelationsCleanupService } from './account-relations-cleanup.service';

describe('AccountRelationsCleanupService', () => {
  const userId = new Types.ObjectId().toString();

  function fakeModel(found: { _id: Types.ObjectId }[] = []) {
    return {
      find: jest.fn().mockResolvedValue(found),
      deleteMany: jest.fn().mockResolvedValue({}),
      updateMany: jest.fn().mockResolvedValue({}),
    };
  }

  function build() {
    const invitationId = new Types.ObjectId();
    const coachInvitationId = new Types.ObjectId();
    const eventId = new Types.ObjectId();
    const models = {
      playerInvitation: fakeModel([{ _id: invitationId }]),
      clubMembership: fakeModel(),
      coachInvitation: fakeModel([{ _id: coachInvitationId }]),
      managedPlayer: fakeModel(),
      savedPlayer: fakeModel(),
      calendarEvent: fakeModel([{ _id: eventId }]),
      order: fakeModel(),
    };
    const service = new AccountRelationsCleanupService(
      models.playerInvitation as never,
      models.clubMembership as never,
      models.coachInvitation as never,
      models.managedPlayer as never,
      models.savedPlayer as never,
      models.calendarEvent as never,
      models.order as never,
    );
    return {
      service,
      models,
      ids: [invitationId, coachInvitationId, eventId],
    };
  }

  it('deletes every relationship on either side and returns the ids to clear notifications for', async () => {
    const { service, models, ids } = build();

    const result = await service.deleteAllForUser(userId);

    const id = new Types.ObjectId(userId);
    expect(models.playerInvitation.deleteMany).toHaveBeenCalledWith({
      $or: [{ clubUserId: id }, { playerUserId: id }],
    });
    expect(models.coachInvitation.deleteMany).toHaveBeenCalledWith({
      $or: [{ clubUserId: id }, { coachUserId: id }],
    });
    expect(models.clubMembership.deleteMany).toHaveBeenCalledWith({
      $or: [{ clubUserId: id }, { playerUserId: id }],
    });
    expect(models.managedPlayer.deleteMany).toHaveBeenCalledWith({
      $or: [{ userId: id }, { clubId: id }],
    });
    expect(models.savedPlayer.deleteMany).toHaveBeenCalledWith({
      clubUserId: id,
    });
    expect(models.calendarEvent.deleteMany).toHaveBeenCalledWith({
      clubUserId: id,
    });
    expect(result).toEqual(ids);
  });

  it('keeps store orders but unlinks them from the account', async () => {
    const { service, models } = build();

    await service.deleteAllForUser(userId);

    expect(models.order.deleteMany).not.toHaveBeenCalled();
    expect(models.order.updateMany).toHaveBeenCalledWith(
      { userId: new Types.ObjectId(userId) },
      { $unset: { userId: 1 } },
    );
  });

  it('pulls a player off other clubs rosters and match stats only when given their profile id', async () => {
    const { service, models } = build();

    await service.deleteAllForUser(userId);
    expect(models.calendarEvent.updateMany).not.toHaveBeenCalled();

    const profileId = new Types.ObjectId();
    await service.deleteAllForUser(userId, profileId);
    expect(models.calendarEvent.updateMany).toHaveBeenCalledWith(
      {
        $or: [
          { 'participants.playerId': profileId },
          { 'matchStats.playerId': profileId },
        ],
      },
      {
        $pull: {
          participants: { playerId: profileId },
          matchStats: { playerId: profileId },
        },
      },
    );
  });
});
