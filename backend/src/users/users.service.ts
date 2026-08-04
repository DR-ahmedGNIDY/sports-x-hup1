import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcryptjs';
import { Model } from 'mongoose';
import { UpdateUserDto } from './dto/update-user.dto';
import {
  User,
  UserDocument,
  UserRole,
  UserStatus,
} from './schemas/user.schema';

const PASSWORD_SALT_ROUNDS = 10;
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

  async deleteById(id: string): Promise<void> {
    await this.findByIdOrThrow(id);
    await this.userModel.deleteOne({ _id: id });
  }
}
