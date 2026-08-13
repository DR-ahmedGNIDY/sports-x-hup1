import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { generateStrongPassword } from '../common/password-generator';
import { getDialCode } from '../countries/dial-codes';
import { UpdatePlayerProfileDto } from '../players/dto/update-player-profile.dto';
import { PlayersService } from '../players/players.service';
import {
  PlayerProfileDocument,
  ProfileVisibility,
} from '../players/schemas/player-profile.schema';
import * as bcrypt from 'bcryptjs';
import { PASSWORD_SALT_ROUNDS, UsersService } from '../users/users.service';
import { CreateClubPlayerDto } from './dto/create-club-player.dto';
import {
  ClubManagedPlayer,
  ClubManagedPlayerDocument,
} from './schemas/club-managed-player.schema';

export interface Credentials {
  username: string;
  password: string;
}

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

  async listForClub(clubId: string): Promise<
    Array<{
      ownership: ClubManagedPlayerDocument;
      profile: PlayerProfileDocument | null;
    }>
  > {
    const ownerships = await this.clubManagedPlayerModel
      .find({ clubId })
      .sort({ createdAt: -1 });
    const userIds = ownerships.map((o) => o.userId.toString());
    if (userIds.length === 0) return [];

    const profiles = await this.playersService.findManyByUserIds(userIds);
    const profileByUserId = new Map(
      profiles.map((p) => [p.userId.toString(), p]),
    );
    return ownerships.map((ownership) => ({
      ownership,
      profile: profileByUserId.get(ownership.userId.toString()) ?? null,
    }));
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
