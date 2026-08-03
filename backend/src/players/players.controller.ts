import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
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
import { UploadMediaDto } from './dto/upload-media.dto';
import { toOwnerView, toPublicView } from './players.mapper';
import { PlayersService } from './players.service';

@Controller('players')
export class PlayersController {
  constructor(private readonly playersService: PlayersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(@CurrentUser() user: JwtPayload) {
    const profile = await this.playersService.getOrCreateForUser(user.sub);
    return toOwnerView(profile);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  async updateMe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdatePlayerProfileDto,
  ) {
    const profile = await this.playersService.updateProfile(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/visibility')
  @UseGuards(JwtAuthGuard)
  async updateVisibility(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateVisibilityDto,
  ) {
    const profile = await this.playersService.updateVisibility(user.sub, dto);
    return toOwnerView(profile);
  }

  @Post('me/media')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async addMedia(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadMediaDto,
  ) {
    const profile = await this.playersService.addMedia(
      user.sub,
      file,
      dto.type,
      dto.isProfilePhoto ?? false,
    );
    return toOwnerView(profile);
  }

  @Delete('me/media/:id')
  @UseGuards(JwtAuthGuard)
  async removeMedia(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    const profile = await this.playersService.removeMedia(user.sub, id);
    return toOwnerView(profile);
  }

  @Post('me/achievements')
  @UseGuards(JwtAuthGuard)
  async addAchievement(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateAchievementDto,
  ) {
    const profile = await this.playersService.addAchievement(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/achievements/:id')
  @UseGuards(JwtAuthGuard)
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
  @UseGuards(JwtAuthGuard)
  async removeAchievement(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    const profile = await this.playersService.removeAchievement(user.sub, id);
    return toOwnerView(profile);
  }

  @Post('me/social-links')
  @UseGuards(JwtAuthGuard)
  async addSocialLink(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateSocialLinkDto,
  ) {
    const profile = await this.playersService.addSocialLink(user.sub, dto);
    return toOwnerView(profile);
  }

  @Patch('me/social-links/:id')
  @UseGuards(JwtAuthGuard)
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
  @UseGuards(JwtAuthGuard)
  async removeSocialLink(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    const profile = await this.playersService.removeSocialLink(user.sub, id);
    return toOwnerView(profile);
  }

  @Get(':id')
  async findPublic(@Param('id') id: string) {
    const profile = await this.playersService.findPublicByIdOrThrow(id);
    return toPublicView(profile);
  }
}
