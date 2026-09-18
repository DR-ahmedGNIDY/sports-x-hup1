import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CODE_LOOKUP_THROTTLE } from '../common/throttle.config';
import {
  imageUploadOptions,
  mediaUploadOptions,
} from '../common/upload.config';
import {
  CreateAchievementDto,
  UpdateAchievementDto,
} from '../players/dto/achievement.dto';
import {
  CreateSocialLinkDto,
  UpdateSocialLinkDto,
} from '../players/dto/social-link.dto';
import { UpdateVisibilityDto } from '../players/dto/update-visibility.dto';
import { MediaType } from '../players/schemas/player-profile.schema';
import { UserRole } from '../users/schemas/user.schema';
import { CoachClubsService } from './coach-clubs.service';
import {
  toCoachOwnerView,
  toCoachPublicView,
  toCoachSearchResultView,
} from './coaches.mapper';
import { CoachCvSection, CoachesService } from './coaches.service';
import { AddCoachMediaDto } from './dto/add-coach-media.dto';
import {
  CreateCertificationDto,
  CreateExperienceDto,
  UpdateCertificationDto,
  UpdateExperienceDto,
} from './dto/cv-entries.dto';
import { SearchCoachesDto } from './dto/search-coaches.dto';
import { UpdateCoachProfileDto } from './dto/update-coach-profile.dto';
import { CoachProfileDocument } from './schemas/coach-profile.schema';

// Every /coaches/me route answers with the full owner view, so the editor can
// replace its state from the response instead of refetching.
@Controller('coaches')
export class CoachesController {
  constructor(
    private readonly coaches: CoachesService,
    private readonly coachClubs: CoachClubsService,
  ) {}

  private async owner(profile: CoachProfileDocument) {
    const clubs = await this.coachClubs.currentClubsFor(
      profile.userId.toString(),
    );
    return toCoachOwnerView(profile, clubs);
  }

  @Get()
  async search(@Query() dto: SearchCoachesDto) {
    const result = await this.coaches.search(dto);
    return {
      items: result.items.map(toCoachSearchResultView),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async me(@CurrentUser() user: JwtPayload) {
    return this.owner(await this.coaches.getOrCreateForUser(user.sub));
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async update(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateCoachProfileDto,
  ) {
    return this.owner(await this.coaches.updateProfile(user.sub, dto));
  }

  @Patch('me/visibility')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async visibility(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateVisibilityDto,
  ) {
    return this.owner(
      await this.coaches.updateVisibility(user.sub, dto.visibility),
    );
  }

  @Post('me/profile-photo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async setPhoto(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.owner(await this.coaches.setProfilePhoto(user.sub, file));
  }

  @Delete('me/profile-photo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async removePhoto(@CurrentUser() user: JwtPayload) {
    return this.owner(await this.coaches.removeProfilePhoto(user.sub));
  }

  @Post('me/media')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  @UseInterceptors(FileInterceptor('file', mediaUploadOptions))
  async addMedia(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: AddCoachMediaDto,
  ) {
    return this.owner(
      await this.coaches.addMedia(
        user.sub,
        file,
        dto.type ?? MediaType.PHOTO,
        dto.caption,
      ),
    );
  }

  @Delete('me/media/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  async removeMedia(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.owner(await this.coaches.removeMedia(user.sub, id));
  }

  // --------------------------------------------------------- CV sections

  @Post('me/certifications')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  addCertification(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateCertificationDto,
  ) {
    return this.add(user, 'certifications', dto);
  }

  @Patch('me/certifications/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  updateCertification(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateCertificationDto,
  ) {
    return this.change(user, 'certifications', id, dto);
  }

  @Delete('me/certifications/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  removeCertification(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.remove(user, 'certifications', id);
  }

  @Post('me/experience')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  addExperience(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateExperienceDto,
  ) {
    return this.add(user, 'experience', dto);
  }

  @Patch('me/experience/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  updateExperience(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateExperienceDto,
  ) {
    return this.change(user, 'experience', id, dto);
  }

  @Delete('me/experience/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  removeExperience(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.remove(user, 'experience', id);
  }

  @Post('me/achievements')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  addAchievement(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateAchievementDto,
  ) {
    return this.add(user, 'achievements', dto);
  }

  @Patch('me/achievements/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  updateAchievement(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateAchievementDto,
  ) {
    return this.change(user, 'achievements', id, dto);
  }

  @Delete('me/achievements/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  removeAchievement(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.remove(user, 'achievements', id);
  }

  @Post('me/social-links')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  addSocialLink(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateSocialLinkDto,
  ) {
    return this.add(user, 'socialLinks', dto);
  }

  @Patch('me/social-links/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  updateSocialLink(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateSocialLinkDto,
  ) {
    return this.change(user, 'socialLinks', id, dto);
  }

  @Delete('me/social-links/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.COACH)
  removeSocialLink(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.remove(user, 'socialLinks', id);
  }

  private async add(user: JwtPayload, section: CoachCvSection, dto: object) {
    return this.owner(await this.coaches.addEntry(user.sub, section, dto));
  }

  private async change(
    user: JwtPayload,
    section: CoachCvSection,
    id: string,
    dto: object,
  ) {
    return this.owner(
      await this.coaches.updateEntry(user.sub, section, id, dto),
    );
  }

  private async remove(user: JwtPayload, section: CoachCvSection, id: string) {
    return this.owner(await this.coaches.removeEntry(user.sub, section, id));
  }

  // ------------------------------------------------------------- public

  // Before ':id' so "by-code" is never read as an id. Authenticated and
  // throttled like the player lookup: codes are sequential.
  @Get('by-code/:code')
  @UseGuards(JwtAuthGuard)
  @Throttle(CODE_LOOKUP_THROTTLE)
  async findByCode(@Param('code') code: string) {
    const profile = await this.coaches.findPublicByCodeOrThrow(code);
    return toCoachPublicView(
      profile,
      await this.coachClubs.currentClubsFor(profile.userId.toString()),
    );
  }

  @Get(':id')
  async findPublic(@Param('id') id: string) {
    const profile = await this.coaches.findPublicByIdOrThrow(id);
    return toCoachPublicView(
      profile,
      await this.coachClubs.currentClubsFor(profile.userId.toString()),
    );
  }
}
