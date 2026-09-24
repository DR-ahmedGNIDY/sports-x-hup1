import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcryptjs';
import { Model } from 'mongoose';
import { ClubAccessService } from '../club-access/club-access.service';
import { ClubsService } from '../clubs/clubs.service';
import { CoachesService } from '../coaches/coaches.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PlayersService } from '../players/players.service';
import { PostsService } from '../posts/posts.service';
import { VideosService } from '../videos/videos.service';
import { AccountRelationsCleanupService } from './account-relations-cleanup.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { SuspensionDuration, suspensionEndDate } from './suspension';
import {
  User,
  UserDocument,
  UserRole,
  UserStatus,
} from './schemas/user.schema';

export const PASSWORD_SALT_ROUNDS = 10;
const ADMIN_LIST_PAGE_SIZE = 20;

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<User>,
    private readonly playersService: PlayersService,
    private readonly clubsService: ClubsService,
    private readonly videosService: VideosService,
    private readonly coachesService: CoachesService,
    private readonly clubAccess: ClubAccessService,
    private readonly postsService: PostsService,
    private readonly notificationsService: NotificationsService,
    private readonly relationsCleanup: AccountRelationsCleanupService,
  ) {}

  async createPlayerOrClub(
    email: string,
    password: string,
    role: UserRole.PLAYER | UserRole.CLUB | UserRole.COACH,
  ): Promise<UserDocument> {
    const existing = await this.userModel.findOne({
      email: email.toLowerCase(),
    });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    const passwordHash = await bcrypt.hash(password, PASSWORD_SALT_ROUNDS);
    return this.userModel.create({ email, passwordHash, role });
  }

  findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email: email.toLowerCase() });
  }

  // Login accepts either credential: self-registered users have an email,
  // club-created players log in with their phone number instead.
  async findByEmailOrPhone(identifier: string): Promise<UserDocument | null> {
    const byEmail = await this.userModel.findOne({
      email: identifier.toLowerCase(),
    });
    if (byEmail) {
      return byEmail;
    }
    return this.userModel.findOne({ phone: identifier });
  }

  // Used by clubs to create a full player account on a player's behalf —
  // username is the phone number, password is a server-generated random
  // string handed back once (in the create-player response) so it can be
  // sent to the player, never persisted in plaintext.
  async createClubManagedPlayer(input: {
    phone: string;
    email?: string;
    password: string;
  }): Promise<UserDocument> {
    const existingPhone = await this.userModel.findOne({
      phone: input.phone,
    });
    if (existingPhone) {
      throw new ConflictException(
        'An account with this phone number already exists.',
      );
    }
    if (input.email) {
      const existingEmail = await this.userModel.findOne({
        email: input.email.toLowerCase(),
      });
      if (existingEmail) {
        throw new ConflictException(
          'An account with this email already exists.',
        );
      }
    }

    const passwordHash = await bcrypt.hash(
      input.password,
      PASSWORD_SALT_ROUNDS,
    );
    return this.userModel.create({
      phone: input.phone,
      // Omit the key entirely rather than passing `email: undefined` —
      // the field's sparse unique index only skips documents where the
      // path is truly unset, not documents that got an explicit `null`.
      ...(input.email ? { email: input.email } : {}),
      passwordHash,
      role: UserRole.PLAYER,
    });
  }

  findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id);
  }

  async findByIdOrThrow(id: string): Promise<UserDocument> {
    const user = await this.userModel.findById(id);
    if (!user) {
      throw new NotFoundException('User not found.');
    }
    return user;
  }

  async updateAccount(id: string, dto: UpdateUserDto): Promise<UserDocument> {
    const user = await this.findByIdOrThrow(id);

    if (dto.email && dto.email.toLowerCase() !== user.email) {
      const existing = await this.userModel.findOne({
        email: dto.email.toLowerCase(),
      });
      if (existing) {
        throw new ConflictException(
          'An account with this email already exists.',
        );
      }
      user.email = dto.email;
    }

    if (dto.newPassword) {
      const matches = await bcrypt.compare(
        dto.currentPassword ?? '',
        user.passwordHash,
      );
      if (!matches) {
        throw new UnauthorizedException('Current password is incorrect.');
      }
      user.passwordHash = await bcrypt.hash(
        dto.newPassword,
        PASSWORD_SALT_ROUNDS,
      );
    }

    await user.save();
    return user;
  }

  async setPasswordHash(id: string, passwordHash: string): Promise<void> {
    await this.userModel.updateOne({ _id: id }, { passwordHash });
  }

  async findAll(
    page = 1,
    role?: UserRole,
  ): Promise<PaginatedResult<UserDocument>> {
    const filter = role ? { role } : {};
    const [items, total] = await Promise.all([
      this.userModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * ADMIN_LIST_PAGE_SIZE)
        .limit(ADMIN_LIST_PAGE_SIZE),
      this.userModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: ADMIN_LIST_PAGE_SIZE, total };
  }

  async updateStatus(id: string, status: UserStatus): Promise<UserDocument> {
    const user = await this.findByIdOrThrow(id);
    user.status = status;
    if (status === UserStatus.ACTIVE) {
      user.suspendedUntil = undefined;
      user.suspensionReason = undefined;
    }
    await user.save();
    return user;
  }

  // Suspends for a fixed term (or forever, for PERMANENT). Re-suspending an
  // already-suspended user just overwrites the term, which is what an admin
  // extending or shortening a suspension expects.
  async suspend(
    id: string,
    duration: SuspensionDuration,
    reason?: string,
  ): Promise<UserDocument> {
    const user = await this.findByIdOrThrow(id);
    user.status = UserStatus.SUSPENDED;
    user.suspendedUntil = suspensionEndDate(duration);
    user.suspensionReason = reason?.trim() || undefined;
    await user.save();
    return user;
  }

  async reactivate(id: string): Promise<UserDocument> {
    return this.updateStatus(id, UserStatus.ACTIVE);
  }

  // Ends a suspension whose term has elapsed, so the account comes back on
  // its own without an admin (or a cron job) touching it. Returns the user
  // unchanged in every other case, which lets callers treat it as a plain
  // "normalise before checking status" step.
  async liftExpiredSuspension(user: UserDocument): Promise<UserDocument> {
    if (user.status !== UserStatus.SUSPENDED) return user;
    if (!user.suspendedUntil) return user; // permanent
    if (user.suspendedUntil.getTime() > Date.now()) return user;

    user.status = UserStatus.ACTIVE;
    user.suspendedUntil = undefined;
    user.suspensionReason = undefined;
    await user.save();
    return user;
  }

  async setModerator(id: string, isModerator: boolean): Promise<UserDocument> {
    const user = await this.findByIdOrThrow(id);
    user.isModerator = isModerator;
    await user.save();
    return user;
  }

  // Powers the admin dashboard's overview cards. Counts run in parallel and
  // read straight off indexed fields, so this stays one cheap round trip.
  async countsByRole(): Promise<{
    totalUsers: number;
    players: number;
    clubs: number;
    coaches: number;
    admins: number;
    suspended: number;
    moderators: number;
  }> {
    const [totalUsers, players, clubs, coaches, admins, suspended, moderators] =
      await Promise.all([
        this.userModel.countDocuments(),
        this.userModel.countDocuments({ role: UserRole.PLAYER }),
        this.userModel.countDocuments({ role: UserRole.CLUB }),
        this.userModel.countDocuments({ role: UserRole.COACH }),
        this.userModel.countDocuments({ role: UserRole.ADMIN }),
        this.userModel.countDocuments({ status: UserStatus.SUSPENDED }),
        this.userModel.countDocuments({ isModerator: true }),
      ]);
    return {
      totalUsers,
      players,
      clubs,
      coaches,
      admins,
      suspended,
      moderators,
    };
  }

  // Cascades the deletion so nothing is left pointing at a user that no
  // longer exists, and none of their data outlives the account:
  //  - relationships with other accounts: invitations, club memberships,
  //    coach staff memberships, club-managed ownership, bookmarks, a club's
  //    calendar and a player's place on rosters (store orders are kept but
  //    unlinked — see AccountRelationsCleanupService);
  //  - notifications to the user, and to anyone about what was deleted;
  //  - the PlayerProfile/ClubProfile/CoachProfile with its Cloudinary media
  //    and, for a player, every video (with its likes/comments);
  //  - photo posts, and the likes/comments left on other people's content.
  //
  // NOTE: refreshtokens/passwordresettokens are cleared by
  // AuthService.deleteAccount on self-service deletion, not here — those
  // schemas are registered inside AuthModule, which imports UsersModule, so
  // reaching them from here would be a circular module dependency. On admin
  // deletion they expire on their own and are rejected once the user no
  // longer exists.
  async deleteById(id: string): Promise<void> {
    const user = await this.findByIdOrThrow(id);

    // Rosters reference the profile, not the user, so its id is needed
    // before the profile itself is deleted below.
    const playerProfile =
      user.role === UserRole.PLAYER
        ? await this.playersService.findByUserId(id)
        : null;
    const deletedEntityIds = await this.relationsCleanup.deleteAllForUser(
      id,
      playerProfile?._id,
    );
    await this.notificationsService.deleteAllForUser(id, deletedEntityIds);

    if (user.role === UserRole.PLAYER) {
      await this.playersService.deleteProfileAndMediaByUserId(id);
    } else if (user.role === UserRole.CLUB) {
      await this.clubsService.deleteProfileAndLogoByUserId(id);
    } else if (user.role === UserRole.COACH) {
      await this.coachesService.deleteProfileAndMediaByUserId(id);
    }
    // Either side of a coach's staff memberships.
    await this.clubAccess.deleteAllForUser(id);
    await this.videosService.deleteUserFootprint(id);
    await this.postsService.deleteAllForUser(id);
    await this.userModel.deleteOne({ _id: id });
  }
}
