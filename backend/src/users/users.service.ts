import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcryptjs';
import { Model } from 'mongoose';
import { ClubsService } from '../clubs/clubs.service';
import { PlayersService } from '../players/players.service';
import { VideosService } from '../videos/videos.service';
import { UpdateUserDto } from './dto/update-user.dto';
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
  ) {}

  async createPlayerOrClub(
    email: string,
    password: string,
    role: UserRole.PLAYER | UserRole.CLUB,
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

  async findAll(page = 1): Promise<PaginatedResult<UserDocument>> {
    const [items, total] = await Promise.all([
      this.userModel
        .find()
        .sort({ createdAt: -1 })
        .skip((page - 1) * ADMIN_LIST_PAGE_SIZE)
        .limit(ADMIN_LIST_PAGE_SIZE),
      this.userModel.countDocuments(),
    ]);
    return { items, page, pageSize: ADMIN_LIST_PAGE_SIZE, total };
  }

  async updateStatus(id: string, status: UserStatus): Promise<UserDocument> {
    const user = await this.findByIdOrThrow(id);
    user.status = status;
    await user.save();
    return user;
  }

  // Cascades the deletion so nothing reachable is left pointing at a user
  // that no longer exists: the corresponding PlayerProfile/ClubProfile
  // (with their Cloudinary media and, for a player, every video/like/
  // comment they own), plus this user's own footprint as a viewer of other
  // people's videos (likes/comments left elsewhere).
  //
  // NOTE: stale refreshtokens/passwordresettokens for this user are not
  // cleaned up here — those schemas are registered inside AuthModule, and
  // AuthModule imports UsersModule, so importing AuthModule back into
  // UsersModule to reach them would be a circular module dependency. They
  // expire on their own and are rejected once the user no longer exists.
  async deleteById(id: string): Promise<void> {
    const user = await this.findByIdOrThrow(id);
    if (user.role === UserRole.PLAYER) {
      await this.playersService.deleteProfileAndMediaByUserId(id);
    } else if (user.role === UserRole.CLUB) {
      await this.clubsService.deleteProfileAndLogoByUserId(id);
    }
    await this.videosService.deleteUserFootprint(id);
    await this.userModel.deleteOne({ _id: id });
  }
}
