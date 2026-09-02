import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  ClubMembership,
  ClubMembershipDocument,
  MembershipStatus,
} from './schemas/club-membership.schema';

export const DUPLICATE_KEY_ERROR_CODE = 11000;

const ROSTER_PAGE_SIZE = 20;

export interface MembershipPage {
  items: ClubMembershipDocument[];
  page: number;
  pageSize: number;
  total: number;
}

/** Thrown when the player already has an ACTIVE membership. */
export class MembershipConflictError extends Error {}

@Injectable()
export class MembershipsService {
  constructor(
    @InjectModel(ClubMembership.name)
    private readonly membershipModel: Model<ClubMembership>,
  ) {}

  // The insert is the concurrency control, not a preceding read: the partial
  // unique index on { playerUserId } where ACTIVE means exactly one of two
  // simultaneous accepts can succeed. The loser gets a duplicate-key error,
  // which becomes MembershipConflictError so the caller can roll its
  // invitation back — see InvitationsService.accept.
  async create(input: {
    clubUserId: Types.ObjectId | string;
    playerUserId: Types.ObjectId | string;
    invitationId: Types.ObjectId | string;
  }): Promise<ClubMembershipDocument> {
    try {
      return await this.membershipModel.create({
        clubUserId: input.clubUserId,
        playerUserId: input.playerUserId,
        invitationId: input.invitationId,
        status: MembershipStatus.ACTIVE,
        joinedAt: new Date(),
      });
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new MembershipConflictError(
          'This player already belongs to a club.',
        );
      }
      throw error;
    }
  }

  findActiveForPlayer(
    playerUserId: string,
  ): Promise<ClubMembershipDocument | null> {
    return this.membershipModel.findOne({
      playerUserId,
      status: MembershipStatus.ACTIVE,
    });
  }

  findActiveForPlayers(
    playerUserIds: string[],
  ): Promise<ClubMembershipDocument[]> {
    return this.membershipModel.find({
      playerUserId: { $in: playerUserIds },
      status: MembershipStatus.ACTIVE,
    });
  }

  async listActiveForClub(
    clubUserId: string,
    page = 1,
  ): Promise<MembershipPage> {
    const filter = { clubUserId, status: MembershipStatus.ACTIVE };
    const [items, total] = await Promise.all([
      this.membershipModel
        .find(filter)
        .sort({ joinedAt: -1 })
        .skip((page - 1) * ROSTER_PAGE_SIZE)
        .limit(ROSTER_PAGE_SIZE),
      this.membershipModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: ROSTER_PAGE_SIZE, total };
  }

  countActiveForClub(clubUserId: string): Promise<number> {
    return this.membershipModel.countDocuments({
      clubUserId,
      status: MembershipStatus.ACTIVE,
    });
  }

  // Guarded on `status: ACTIVE` so ending an already-ended membership is a
  // no-op rather than rewriting endedAt.
  async end(
    membershipId: Types.ObjectId | string,
  ): Promise<ClubMembershipDocument | null> {
    return this.membershipModel.findOneAndUpdate(
      { _id: membershipId, status: MembershipStatus.ACTIVE },
      { $set: { status: MembershipStatus.ENDED, endedAt: new Date() } },
      { new: true },
    );
  }
}
