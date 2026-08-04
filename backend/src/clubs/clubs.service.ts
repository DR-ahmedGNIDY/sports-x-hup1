import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { UpdateClubProfileDto } from './dto/update-club-profile.dto';
import {
  ClubProfile,
  ClubProfileDocument,
} from './schemas/club-profile.schema';

@Injectable()
export class ClubsService {
  constructor(
    @InjectModel(ClubProfile.name)
    private readonly clubProfileModel: Model<ClubProfile>,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async getOrCreateForUser(userId: string): Promise<ClubProfileDocument> {
    let profile = await this.clubProfileModel.findOne({ userId });
    if (!profile) {
      profile = await this.clubProfileModel.create({ userId });
    }
    return profile;
  }

  async findByIdOrThrow(id: string): Promise<ClubProfileDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Club not found.');
    }
    const profile = await this.clubProfileModel.findById(id);
    if (!profile) {
      throw new NotFoundException('Club not found.');
    }
    return profile;
  }

  async updateProfile(
    userId: string,
    dto: UpdateClubProfileDto,
  ): Promise<ClubProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    Object.assign(profile, dto);
    await profile.save();
    return profile;
  }

  async uploadLogo(
    userId: string,
    file: Express.Multer.File,
  ): Promise<ClubProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    const profile = await this.getOrCreateForUser(userId);
    if (profile.logo) {
      await this.cloudinary.deleteAsset(profile.logo.publicId, 'image');
    }
    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/clubs/${userId}`,
      'image',
    );
    profile.logo = { publicId: upload.publicId, secureUrl: upload.secureUrl };
    await profile.save();
    return profile;
  }
}
