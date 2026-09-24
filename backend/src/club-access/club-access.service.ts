import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { JwtPayload } from '../auth/decorators/current-user.decorator';
import { ClubsService } from '../clubs/clubs.service';
import { MembershipStatus } from '../invitations/schemas/club-membership.schema';
import { UserRole } from '../users/schemas/user.schema';
import { CoachPermission, normalizePermissions } from './coach-permission.enum';
import {
  ClubCoachMembership,
  ClubCoachMembershipDocument,
} from './schemas/club-coach-membership.schema';

export const DUPLICATE_KEY_ERROR_CODE = 11000;

/** Thrown when this coach is already on this club's staff. */
export class CoachMembershipConflictError extends Error {}

// Who is acting for which club. `clubUserId` is what every club endpoint
// already scoped its queries by, so a controller swaps `user.sub` for this
// and nothing below it changes.
export interface ClubActor {
  clubUserId: string;
  actorUserId: string;
  actorRole: UserRole.CLUB | UserRole.COACH;
  /** Everything, for the club itself; the grant, for a coach. */
  permissions: CoachPermission[];
}

const ACCESS_DENIED = 'You do not have access to this club.';

@Injectable()
export class ClubAccessService {
  constructor(
    @InjectModel(ClubCoachMembership.name)
    private readonly membershipModel: Model<ClubCoachMembership>,
    private readonly clubsService: ClubsService,
  ) {}

  // ---------------------------------------------------------- resolving

  // `clubProfileId` is the X-Club-Id header: which of their clubs a coach is
  // acting for. Ignored for a club account, which can only ever act for
  // itself. Every failure a coach can hit — bad id, no such club, not on its
  // staff — is the same 403, so the header can't be used to probe which
  // clubs exist or who works where.
  async resolve(
    user: JwtPayload,
    clubProfileId: string | undefined,
    required?: CoachPermission,
  ): Promise<ClubActor> {
    if (user.role === UserRole.CLUB) {
      return {
        clubUserId: user.sub,
        actorUserId: user.sub,
        actorRole: UserRole.CLUB,
        permissions: Object.values(CoachPermission),
      };
    }
    if (user.role !== UserRole.COACH) {
      throw new ForbiddenException(ACCESS_DENIED);
    }
    if (!clubProfileId || !Types.ObjectId.isValid(clubProfileId)) {
      throw new ForbiddenException(ACCESS_DENIED);
    }

    const clubUserId = await this.clubUserIdForProfile(clubProfileId);
    const membership = clubUserId
      ? await this.findActive(clubUserId, user.sub)
      : null;
    if (!membership) {
      throw new ForbiddenException(ACCESS_DENIED);
    }

    const permissions = normalizePermissions(membership.permissions);
    if (required && !permissions.includes(required)) {
      throw new ForbiddenException(
        'You do not have permission to do this for this club.',
      );
    }
    return {
      clubUserId: membership.clubUserId.toString(),
      actorUserId: user.sub,
      actorRole: UserRole.COACH,
      permissions,
    };
  }

  private async clubUserIdForProfile(
    clubProfileId: string,
  ): Promise<string | null> {
    try {
      const profile = await this.clubsService.findByIdOrThrow(clubProfileId);
      return profile.userId.toString();
    } catch (error) {
      if (error instanceof NotFoundException) return null;
      throw error;
    }
  }

  // --------------------------------------------------------- memberships

  async create(input: {
    clubUserId: Types.ObjectId | string;
    coachUserId: Types.ObjectId | string;
    invitationId: Types.ObjectId | string;
  }): Promise<ClubCoachMembershipDocument> {
    try {
      return await this.membershipModel.create({
        ...input,
        status: MembershipStatus.ACTIVE,
        joinedAt: new Date(),
      });
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new CoachMembershipConflictError(
          'This coach is already on this club’s staff.',
        );
      }
      throw error;
    }
  }

  findActive(
    clubUserId: string | Types.ObjectId,
    coachUserId: string | Types.ObjectId,
  ): Promise<ClubCoachMembershipDocument | null> {
    return this.membershipModel.findOne({
      clubUserId,
      coachUserId,
      status: MembershipStatus.ACTIVE,
    });
  }

  listActiveForCoach(
    coachUserId: string,
  ): Promise<ClubCoachMembershipDocument[]> {
    return this.membershipModel
      .find({ coachUserId, status: MembershipStatus.ACTIVE })
      .sort({ joinedAt: -1 });
  }

  listActiveForClub(
    clubUserId: string,
  ): Promise<ClubCoachMembershipDocument[]> {
    return this.membershipModel
      .find({ clubUserId, status: MembershipStatus.ACTIVE })
      .sort({ joinedAt: -1 });
  }

  // Scoped to the club in the filter itself: a club can only ever touch its
  // own staff, and anyone else's id is simply "not found".
  async setPermissions(
    clubUserId: string,
    membershipId: string,
    permissions: CoachPermission[],
  ): Promise<ClubCoachMembershipDocument> {
    const updated = Types.ObjectId.isValid(membershipId)
      ? await this.membershipModel.findOneAndUpdate(
          {
            _id: membershipId,
            clubUserId,
            status: MembershipStatus.ACTIVE,
          },
          { $set: { permissions: normalizePermissions(permissions) } },
          { new: true },
        )
      : null;
    if (!updated) {
      throw new NotFoundException('Coach not found on your staff.');
    }
    return updated;
  }

  // `party` pins the caller's side into the filter — a club ends a
  // membership of its own staff, a coach ends one of their own.
  async end(
    party: { clubUserId: string } | { coachUserId: string },
    membershipId: string,
  ): Promise<ClubCoachMembershipDocument> {
    const ended = Types.ObjectId.isValid(membershipId)
      ? await this.membershipModel.findOneAndUpdate(
          { _id: membershipId, ...party, status: MembershipStatus.ACTIVE },
          { $set: { status: MembershipStatus.ENDED, endedAt: new Date() } },
          { new: true },
        )
      : null;
    if (!ended) {
      throw new NotFoundException('Membership not found.');
    }
    return ended;
  }

  // Account deletion (self-service or admin): whichever side the deleted
  // account was on. Removed outright, ended ones included, rather than
  // marked ENDED — a deleted account keeps no history here.
  async deleteAllForUser(userId: string): Promise<void> {
    await this.membershipModel.deleteMany({
      $or: [{ clubUserId: userId }, { coachUserId: userId }],
    });
  }
}
