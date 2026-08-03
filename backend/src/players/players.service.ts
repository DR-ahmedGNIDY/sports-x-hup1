import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  CloudinaryResourceType,
  CloudinaryService,
} from '../cloudinary/cloudinary.service';
import {
  CreateAchievementDto,
  UpdateAchievementDto,
} from './dto/achievement.dto';
import {
  CreateSocialLinkDto,
  UpdateSocialLinkDto,
} from './dto/social-link.dto';
import { UpdatePlayerProfileDto } from './dto/update-player-profile.dto';
import { UpdateVisibilityDto } from './dto/update-visibility.dto';
import {
  MediaType,
  PlayerProfile,
  PlayerProfileDocument,
  ProfileVisibility,
} from './schemas/player-profile.schema';

function resourceTypeFor(type: MediaType): CloudinaryResourceType {
  return type === MediaType.VIDEO ? 'video' : 'image';
}

@Injectable()
export class PlayersService {
  constructor(
    @InjectModel(PlayerProfile.name)
    private readonly playerProfileModel: Model<PlayerProfile>,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async getOrCreateForUser(userId: string): Promise<PlayerProfileDocument> {
    let profile = await this.playerProfileModel.findOne({ userId });
    if (!profile) {
      profile = await this.playerProfileModel.create({ userId });
    }
    return profile;
  }

  async findPublicByIdOrThrow(id: string): Promise<PlayerProfileDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Player not found.');
    }
    const profile = await this.playerProfileModel.findById(id);
    if (!profile || profile.visibility !== ProfileVisibility.PUBLIC) {
      throw new NotFoundException('Player not found.');
    }
    return profile;
  }

  async updateProfile(
    userId: string,
    dto: UpdatePlayerProfileDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    Object.assign(profile, dto);
    if (dto.dateOfBirth) {
      profile.dateOfBirth = new Date(dto.dateOfBirth);
    }
    await profile.save();
    return profile;
  }

  async updateVisibility(
    userId: string,
    dto: UpdateVisibilityDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    profile.visibility = dto.visibility;
    await profile.save();
    return profile;
  }

  async addMedia(
    userId: string,
    file: Express.Multer.File,
    type: MediaType,
    isProfilePhoto: boolean,
  ): Promise<PlayerProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    const profile = await this.getOrCreateForUser(userId);
    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/players/${userId}`,
      resourceTypeFor(type),
    );

    if (type === MediaType.PHOTO && isProfilePhoto) {
      profile.media.forEach((item) => {
        if (item.type === MediaType.PHOTO) {
          item.isProfilePhoto = false;
        }
      });
    }

    profile.media.push({
      type,
      publicId: upload.publicId,
      secureUrl: upload.secureUrl,
      isProfilePhoto: type === MediaType.PHOTO ? isProfilePhoto : false,
    });
    await profile.save();
    return profile;
  }

  async removeMedia(
    userId: string,
    mediaId: string,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const media = profile.media.find(
      (item) => item._id?.toString() === mediaId,
    );
    if (!media) {
      throw new NotFoundException('Media item not found.');
    }
    await this.cloudinary.deleteAsset(
      media.publicId,
      resourceTypeFor(media.type),
    );
    profile.media = profile.media.filter(
      (item) => item._id?.toString() !== mediaId,
    ) as typeof profile.media;
    await profile.save();
    return profile;
  }

  async addAchievement(
    userId: string,
    dto: CreateAchievementDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    profile.achievements.push(dto);
    await profile.save();
    return profile;
  }

  async updateAchievement(
    userId: string,
    achievementId: string,
    dto: UpdateAchievementDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const achievement = profile.achievements.find(
      (item) => item._id?.toString() === achievementId,
    );
    if (!achievement) {
      throw new NotFoundException('Achievement not found.');
    }
    Object.assign(achievement, dto);
    await profile.save();
    return profile;
  }

  async removeAchievement(
    userId: string,
    achievementId: string,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const exists = profile.achievements.some(
      (item) => item._id?.toString() === achievementId,
    );
    if (!exists) {
      throw new NotFoundException('Achievement not found.');
    }
    profile.achievements = profile.achievements.filter(
      (item) => item._id?.toString() !== achievementId,
    ) as typeof profile.achievements;
    await profile.save();
    return profile;
  }

  async addSocialLink(
    userId: string,
    dto: CreateSocialLinkDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    profile.socialLinks.push(dto);
    await profile.save();
    return profile;
  }

  async updateSocialLink(
    userId: string,
    linkId: string,
    dto: UpdateSocialLinkDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const link = profile.socialLinks.find(
      (item) => item._id?.toString() === linkId,
    );
    if (!link) {
      throw new NotFoundException('Social link not found.');
    }
    Object.assign(link, dto);
    await profile.save();
    return profile;
  }

  async removeSocialLink(
    userId: string,
    linkId: string,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const exists = profile.socialLinks.some(
      (item) => item._id?.toString() === linkId,
    );
    if (!exists) {
      throw new NotFoundException('Social link not found.');
    }
    profile.socialLinks = profile.socialLinks.filter(
      (item) => item._id?.toString() !== linkId,
    ) as typeof profile.socialLinks;
    await profile.save();
    return profile;
  }
}
