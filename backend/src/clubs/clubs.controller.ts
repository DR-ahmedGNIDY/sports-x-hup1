import {
  Body,
  Controller,
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
import { imageUploadOptions } from '../common/upload.config';
import { UserRole } from '../users/schemas/user.schema';
import { ClubsService } from './clubs.service';
import { ListClubsDto } from './dto/list-clubs.dto';
import { UpdateClubProfileDto } from './dto/update-club-profile.dto';
import { toClubView } from './clubs.mapper';

@Controller('clubs')
export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  // Public Clubs listing (Phase 5) — GET /clubs (no trailing segment), so
  // it never collides with GET /clubs/me or GET /clubs/:id below.
  @Get()
  async findAllPublic(@Query() query: ListClubsDto) {
    const result = await this.clubsService.findAllPublic(
      query.page ?? 1,
      query.country,
    );
    return { ...result, items: result.items.map(toClubView) };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  async me(@CurrentUser() user: JwtPayload) {
    const profile = await this.clubsService.getOrCreateForUser(user.sub);
    return toClubView(profile);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  async updateMe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateClubProfileDto,
  ) {
    const profile = await this.clubsService.updateProfile(user.sub, dto);
    return toClubView(profile);
  }

  @Post('me/logo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLUB)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async uploadLogo(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const profile = await this.clubsService.uploadLogo(user.sub, file);
    return toClubView(profile);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const profile = await this.clubsService.findByIdOrThrow(id);
    return toClubView(profile);
  }
}
