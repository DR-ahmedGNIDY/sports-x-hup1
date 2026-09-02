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
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CODE_LOOKUP_THROTTLE } from '../common/throttle.config';
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
      query.search,
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

  // Registered before the ':id' wildcard below so "by-code" is never matched
  // as a club id. Authenticated (unlike GET /clubs/:id) and throttled well
  // under the global default: codes are sequential, so this is the one route
  // where guessing them in bulk would be cheap — see the plan's §2
  // trade-off note.
  @Get('by-code/:code')
  @UseGuards(JwtAuthGuard)
  @Throttle(CODE_LOOKUP_THROTTLE)
  async findByCode(@Param('code') code: string) {
    const profile = await this.clubsService.findByPublicCodeOrThrow(code);
    return toClubView(profile);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const profile = await this.clubsService.findByIdOrThrow(id);
    return toClubView(profile);
  }
}
