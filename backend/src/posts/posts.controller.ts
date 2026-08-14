import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
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
import { imageUploadOptions } from '../common/upload.config';
import { UserRole } from '../users/schemas/user.schema';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CreatePhotoPostDto } from './dto/create-photo-post.dto';
import { FeedDto } from './dto/feed.dto';
import { PostsService } from './posts.service';

@Controller()
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  // A Player posts from their own profile's sport by default; a Club must
  // choose one (see CreatePhotoPostDto/PostsService.createPost) — both are
  // the only roles a Home feed post can come from.
  @Post('posts')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLAYER, UserRole.CLUB)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async create(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: CreatePhotoPostDto,
  ) {
    return this.postsService.createPost(user.sub, user.role, dto, file);
  }

  // The unified Home feed — Videos + Photo posts merged by date, scoped to
  // one sport, no other filter (see PostsService.homeFeed for why "Home"
  // is deliberately unfiltered where /videos/community still offers a
  // category filter for browsing).
  @Get('feed')
  @UseGuards(JwtAuthGuard)
  async homeFeed(@Query() dto: FeedDto) {
    return this.postsService.homeFeed(dto.sport, dto.page);
  }

  @Post('posts/:id/like')
  @UseGuards(JwtAuthGuard)
  async like(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.postsService.like(user.sub, id);
  }

  @Delete('posts/:id/like')
  @UseGuards(JwtAuthGuard)
  async unlike(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.postsService.unlike(user.sub, id);
  }

  @Get('posts/:id/comments')
  @UseGuards(JwtAuthGuard)
  async listComments(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Query('page') page?: string,
  ) {
    const pageNumber = page ? parseInt(page, 10) : 1;
    return this.postsService.listComments(user.sub, id, pageNumber);
  }

  @Post('posts/:id/comments')
  @UseGuards(JwtAuthGuard)
  async addComment(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.postsService.addComment(user.sub, id, dto);
  }

  @Delete('posts/:id/comments/:commentId')
  @UseGuards(JwtAuthGuard)
  async deleteComment(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Param('commentId') commentId: string,
  ) {
    await this.postsService.deleteComment(user.sub, user.role, id, commentId);
    return { success: true };
  }
}
