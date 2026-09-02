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
import { UserRole } from '../users/schemas/user.schema';
import {
  CreateAchievementDto,
  UpdateAchievementDto,
} from './dto/achievement.dto';
import { SearchPlayersDto } from './dto/search-players.dto';
import {
  CreateSocialLinkDto,
  UpdateSocialLinkDto,
} from './dto/social-link.dto';
import { UpdatePlayerProfileDto } from './dto/update-player-profile.dto';
import { UpdateVisibilityDto } from './dto/update-visibility.dto';
import {
  toOwnerView,
  toPublicView,
  toSearchResultView,
  toStatsView,
} from './players.mapper';
import { PlayersService } from './players.service';

@Controller('players')
export class PlayersController {
  constructor(private readonly playersService: PlayersService) {}

  @Get()
  async search(@Query() dto: SearchPlayersDto) {
    const result = await this.playersService.search(dto);
    return {
      items: result.items.map(toSearchResultView),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async me(@CurrentUser() user: JwtPayload) {
    const profile = await this.playersService.getOrCreateForUser(user.sub);
    return toOwnerView(profile);
  }

  // Registered ahead of the `:id` wildcard route below so "stats" is never
  // matched as a player id.
  @Get('me/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async myStats(@CurrentUser() user: JwtPayload) {
    const { profile, savedByClubsCount } =
      await this.playersService.getStatsForUser(user.sub);
    return toStatsView(profile, savedByClubsCount);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async updateMe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdatePlayerProfileDto,
  ) {
    const profile = await this.playersService.updateProfile(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/visibility')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async updateVisibility(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateVisibilityDto,
  ) {
    const profile = await this.playersService.updateVisibility(user.sub, dto);
    return toOwnerView(profile);
  }

  @Post('me/media')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  @UseInterceptors(FileInterceptor('file', mediaUploadOptions))
  async addMedia(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const profile = await this.playersService.addMedia(user.sub, file);
    return toOwnerView(profile);
  }

  @Delete('me/media/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async removeMedia(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const profile = await this.playersService.removeMedia(user.sub, id);
    return toOwnerView(profile);
  }

  @Post('me/profile-photo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async setProfilePhoto(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const profile = await this.playersService.setProfilePhoto(user.sub, file);
    return toOwnerView(profile);
  }

  @Delete('me/profile-photo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async removeProfilePhoto(@CurrentUser() user: JwtPayload) {
    const profile = await this.playersService.removeProfilePhoto(user.sub);
    return toOwnerView(profile);
  }

  @Post('me/achievements')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async addAchievement(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateAchievementDto,
  ) {
    const profile = await this.playersService.addAchievement(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/achievements/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async updateAchievement(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateAchievementDto,
  ) {
    const profile = await this.playersService.updateAchievement(
      user.sub,
      id,
      dto,
    );
    return toOwnerView(profile);
  }

  @Delete('me/achievements/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async removeAchievement(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    const profile = await this.playersService.removeAchievement(user.sub, id);
    return toOwnerView(profile);
  }

  @Post('me/social-links')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async addSocialLink(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateSocialLinkDto,
  ) {
    const profile = await this.playersService.addSocialLink(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/social-links/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async updateSocialLink(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateSocialLinkDto,
  ) {
    const profile = await this.playersService.updateSocialLink(
      user.sub,
      id,
      dto,
    );
    return toOwnerView(profile);
  }

  @Delete('me/social-links/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async removeSocialLink(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    const profile = await this.playersService.removeSocialLink(user.sub, id);
    return toOwnerView(profile);
  }

  // Registered before the ':id' wildcard below so "by-code" is never matched
  // as a player id. Authenticated (unlike GET /players/:id) and throttled
  // well under the global default — codes are sequential, so bulk guessing
  // is the one thing worth making expensive here. Still PUBLIC-only: a code
  // is not a way around a player's visibility setting.
  @Get('by-code/:code')
  @UseGuards(JwtAuthGuard)
  @Throttle(CODE_LOOKUP_THROTTLE)
  async findByCode(@Param('code') code: string) {
    const profile = await this.playersService.findPublicByCodeOrThrow(code);
    return toPublicView(profile);
  }

  @Get(':id/contact')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  async contact(@Param('id') id: string) {
    const profile = await this.playersService.findPublicByIdOrThrow(id);
    return profile.contact;
  }

  @Get(':id')
  async findPublic(@Param('id') id: string) {
    const profile = await this.playersService.findPublicByIdOrThrow(id);
    return toPublicView(profile);
  }
}
