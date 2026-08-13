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
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { videoUploadOptions } from '../common/upload.config';
import { UserRole } from '../users/schemas/user.schema';
import { CommunityFeedDto } from './dto/community-feed.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ListVideosDto } from './dto/list-videos.dto';
import { UpdateVideoVisibilityDto } from './dto/update-video-visibility.dto';
import { UploadVideoDto } from './dto/upload-video.dto';
import { VideosService } from './videos.service';

@Controller('videos')
export class VideosController {
  constructor(private readonly videosService: VideosService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  @UseInterceptors(FileInterceptor('file', videoUploadOptions))
  async upload(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadVideoDto,
  ) {
    return this.videosService.uploadVideo(user.sub, dto, file);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async listMine(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListVideosDto,
  ) {
    return this.videosService.listMine(user.sub, dto.category);
  }

  // Registered ahead of the `:id` wildcard routes below so "community" is
  // never matched as a video id.
  @Get('community')
  @UseGuards(JwtAuthGuard)
  async communityFeed(@Query() dto: CommunityFeedDto) {
    return this.videosService.communityFeed(dto.sport, dto.category, dto.page);
  }

  @Get('player/:playerId')
  async listForPlayer(
    @Param('playerId') playerId: string,
    @Query('category') category?: string,
  ) {
    return this.videosService.listForPlayer(playerId, category);
  }

  @Patch(':id/visibility')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async updateVisibility(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateVideoVisibilityDto,
  ) {
    return this.videosService.updateVisibility(user.sub, id, dto.visibility);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER)
  async deleteVideo(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.videosService.deleteVideo(user.sub, id);
    return { success: true };
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  async like(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.videosService.like(user.sub, id);
  }

  @Delete(':id/like')
  @UseGuards(JwtAuthGuard)
  async unlike(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.videosService.unlike(user.sub, id);
  }

  @Get(':id/comments')
  @UseGuards(JwtAuthGuard)
  async listComments(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Query('page') page?: string,
  ) {
    const pageNumber = page ? parseInt(page, 10) : 1;
    return this.videosService.listComments(user.sub, id, pageNumber);
  }

  @Post(':id/comments')
  @UseGuards(JwtAuthGuard)
  async addComment(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.videosService.addComment(user.sub, id, dto);
  }

  @Delete(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard)
  async deleteComment(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Param('commentId') commentId: string,
  ) {
    await this.videosService.deleteComment(user.sub, user.role, id, commentId);
    return { success: true };
  }
}
