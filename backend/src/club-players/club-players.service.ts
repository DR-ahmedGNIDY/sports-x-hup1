import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { generateStrongPassword } from '../common/password-generator';
import { getDialCode } from '../countries/dial-codes';
import {
  completionPercentFor,
  isProfileComplete,
  missingFieldsFor,
} from '../players/players.mapper';
import { UpdatePlayerProfileDto } from '../players/dto/update-player-profile.dto';
import { PlayerSearchResult, PlayersService } from '../players/players.service';
import {
  PlayerProfileDocument,
  ProfileVisibility,
} from '../players/schemas/player-profile.schema';
import * as bcrypt from 'bcryptjs';
import { PASSWORD_SALT_ROUNDS, UsersService } from '../users/users.service';
import { CreateClubPlayerDto } from './dto/create-club-player.dto';
import { ListClubPlayersDto } from './dto/list-club-players.dto';
import {
  ClubManagedPlayer,
  ClubManagedPlayerDocument,
} from './schemas/club-managed-player.schema';

export interface Credentials {
  username: string;
  password: string;
}

export interface ClubRosterPage {
  items: Array<{ profile: PlayerProfileDocument; dialCode: string }>;
  page: number;
  pageSize: number;
  total: number;
}

export interface ClubPlayersSummary {
  totalPlayers: number;
  completeProfiles: number;
  incompleteProfiles: number;
  // Roster-wide average of the same per-player completion percentage
  // `GET /players/me/stats` uses — `null` for an empty roster (nothing to
  // average), never fabricated.
  averageCompletionPercent: number | null;
  // The 3 most-frequently-missing fields across the roster (keys into the
  // same `missingFieldLabel` lookup the Player Dashboard already uses) —
  // omits fields nobody is missing rather than padding to a fixed length.
  topMissingFields: string[];
  // Newest-first, capped — a Dashboard summary tile, not a roster page.
  recentPlayers: Array<{ profile: PlayerProfileDocument; dialCode: string }>;
}

const RECENT_PLAYERS_LIMIT = 5;
const TOP_MISSING_FIELDS_LIMIT = 3;

@Injectable()
export class ClubPlayersService {
  constructor(
    @InjectModel(ClubManagedPlayer.name)
    private readonly clubManagedPlayerModel: Model<ClubManagedPlayer>,
    private readonly usersService: UsersService,
    private readonly playersService: PlayersService,
  ) {}

  private normalizePhone(dialCode: string, localDigits: string): string {
    return `${dialCode}${localDigits.replace(/^0+/, '')}`;
  }

  async createPlayer(
    clubId: string,
    dto: CreateClubPlayerDto,
  ): Promise<{
    player: PlayerProfileDocument;
    credentials: Credentials;
    dialCode: string;
  }> {
    const dialCode = getDialCode(dto.countryIsoCode);
    const normalizedPhone = this.normalizePhone(dialCode, dto.phone);
    const plaintextPassword = generateStrongPassword();

    const user = await this.usersService.createClubManagedPlayer({
      phone: normalizedPhone,
      email: dto.email,
      password: plaintextPassword,
    });

    const profile = await this.playersService.updateProfile(user.id, {
      firstName: dto.firstName,
      lastName: dto.lastName,
      dateOfBirth: dto.dateOfBirth,
      nationality: dto.nationality,
      country: dto.country ?? dto.countryIsoCode,
      city: dto.city,
      sport: dto.sport,
      position: dto.position,
      preferredFoot: dto.preferredFoot,
      height: dto.height,
      weight: dto.weight,
      currentStatus: dto.currentStatus,
      currentClub: dto.currentClub,
      bio: dto.bio,
      contact: {
        ...dto.contact,
        phone: normalizedPhone,
        email: dto.email,
      },
    });
    // The whole point of a club-created profile is to be discoverable, so
    // it goes public immediately rather than sitting on the PRIVATE default
    // (the player never logs in to flip it themselves right after signup).
    profile.visibility = ProfileVisibility.PUBLIC;
    await profile.save();

    await this.clubManagedPlayerModel.create({
      userId: user.id,
      clubId,
      dialCode,
    });

    return {
      player: profile,
      credentials: { username: normalizedPhone, password: plaintextPassword },
      dialCode,
    };
  }

  private async requireOwnership(
    clubId: string,
    userId: string,
  ): Promise<ClubManagedPlayerDocument> {
    const ownership = await this.clubManagedPlayerModel.findOne({
      clubId,
      userId,
    });
    if (!ownership) {
      throw new ForbiddenException('This player is not managed by your club.');
    }
    return ownership;
  }

  // Every ownership row for the club — cheap (userId + dialCode only,
  // no profile data) and bounded by what this one club created, so
  // fetching it in full (rather than paginating it too) doesn't risk the
  // "download everything" problem GET /club-players itself avoids: the
  // heavy part (full PlayerProfile documents) is still paginated below.
  private async ownershipsForClub(
    clubId: string,
  ): Promise<ClubManagedPlayerDocument[]> {
    return this.clubManagedPlayerModel.find({ clubId }).sort({ createdAt: -1 });
  }

  // Paginated + optionally filtered by name/phone search and sport/
  // position — see PlayersService.findManyByUserIdsFiltered for how the
  // actual query stays bounded to this club's own roster.
  async listForClub(
    clubId: string,
    dto: ListClubPlayersDto,
  ): Promise<ClubRosterPage> {
    const ownerships = await this.ownershipsForClub(clubId);
    const userIds = ownerships.map((o) => o.userId.toString());
    if (userIds.length === 0) {
      return { items: [], page: dto.page ?? 1, pageSize: 20, total: 0 };
    }

    const dialCodeByUserId = new Map(
      ownerships.map((o) => [o.userId.toString(), o.dialCode]),
    );
    const result: PlayerSearchResult =
      await this.playersService.findManyByUserIdsFiltered(userIds, {
        search: dto.search,
        sport: dto.sport,
        position: dto.position,
        birthYear: dto.birthYear,
        page: dto.page,
      });
    return {
      items: result.items.map((profile) => ({
        profile,
        dialCode: dialCodeByUserId.get(profile.userId.toString()) ?? '',
      })),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  // Powers the Club Dashboard's summary tiles — total/complete/incomplete
  // counts and the 5 most-recently-added players. Deliberately not
  // paginated (it needs to look at every managed player once to count
  // completeness), but the response sent back to the client stays small
  // regardless of roster size: 3 numbers + up to 5 players, never the
  // full roster.
  async getSummaryForClub(clubId: string): Promise<ClubPlayersSummary> {
    const ownerships = await this.ownershipsForClub(clubId);
    const userIds = ownerships.map((o) => o.userId.toString());
    if (userIds.length === 0) {
      return {
        totalPlayers: 0,
        completeProfiles: 0,
        incompleteProfiles: 0,
        averageCompletionPercent: null,
        topMissingFields: [],
        recentPlayers: [],
      };
    }

    const dialCodeByUserId = new Map(
      ownerships.map((o) => [o.userId.toString(), o.dialCode]),
    );
    const profiles = await this.playersService.findManyByUserIds(userIds);
    const profileByUserId = new Map(
      profiles.map((p) => [p.userId.toString(), p]),
    );

    const completeProfiles = profiles.filter(isProfileComplete).length;
    const averageCompletionPercent = Math.round(
      profiles.reduce((sum, p) => sum + completionPercentFor(p), 0) /
        profiles.length,
    );
    const missingFieldCounts = new Map<string, number>();
    for (const profile of profiles) {
      for (const field of missingFieldsFor(profile)) {
        missingFieldCounts.set(field, (missingFieldCounts.get(field) ?? 0) + 1);
      }
    }
    const topMissingFields = [...missingFieldCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, TOP_MISSING_FIELDS_LIMIT)
      .map(([field]) => field);
    // `ownerships` is already newest-first; not every ownership row is
    // guaranteed to have a matching profile (defensive, same as the old
    // listForClub's null-profile filter).
    const recentPlayers = userIds
      .map((id) => profileByUserId.get(id))
      .filter((profile): profile is PlayerProfileDocument => Boolean(profile))
      .slice(0, RECENT_PLAYERS_LIMIT)
      .map((profile) => ({
        profile,
        dialCode: dialCodeByUserId.get(profile.userId.toString()) ?? '',
      }));

    return {
      totalPlayers: userIds.length,
      completeProfiles,
      incompleteProfiles: userIds.length - completeProfiles,
      averageCompletionPercent,
      topMissingFields,
      recentPlayers,
    };
  }

  async getOneForClub(
    clubId: string,
    userId: string,
  ): Promise<{ profile: PlayerProfileDocument; dialCode: string }> {
    const ownership = await this.requireOwnership(clubId, userId);
    const profile = await this.playersService.getOrCreateForUser(userId);
    return { profile, dialCode: ownership.dialCode };
  }

  async updatePlayer(
    clubId: string,
    userId: string,
    dto: UpdatePlayerProfileDto,
  ): Promise<{ profile: PlayerProfileDocument; dialCode: string }> {
    const ownership = await this.requireOwnership(clubId, userId);
    const profile = await this.playersService.updateProfile(userId, dto);
    return { profile, dialCode: ownership.dialCode };
  }

  async uploadPhoto(
    clubId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ profile: PlayerProfileDocument; dialCode: string }> {
    const ownership = await this.requireOwnership(clubId, userId);
    const profile = await this.playersService.setProfilePhoto(userId, file);
    return { profile, dialCode: ownership.dialCode };
  }

  // Removes only the club's ownership record — the player's User account
  // and PlayerProfile are untouched and stay fully usable (they can still
  // log in, their profile stays visible per its own visibility setting).
  // Deliberately not the same operation as deleting a player's account;
  // callers must not conflate the two.
  async removeFromClub(clubId: string, userId: string): Promise<void> {
    const ownership = await this.requireOwnership(clubId, userId);
    await this.clubManagedPlayerModel.deleteOne({ _id: ownership._id });
  }

  // Old password is unrecoverable once hashed, so "resend" really means
  // "issue a new one" — used both for a lost first message and for
  // deliberate rotation.
  async resendCredentials(
    clubId: string,
    userId: string,
  ): Promise<Credentials> {
    await this.requireOwnership(clubId, userId);
    const user = await this.usersService.findByIdOrThrow(userId);
    if (!user.phone) {
      throw new NotFoundException(
        'This player account has no phone number on file.',
      );
    }
    const plaintextPassword = generateStrongPassword();
    const passwordHash = await bcrypt.hash(
      plaintextPassword,
      PASSWORD_SALT_ROUNDS,
    );
    await this.usersService.setPasswordHash(userId, passwordHash);
    return { username: user.phone, password: plaintextPassword };
  }
}
