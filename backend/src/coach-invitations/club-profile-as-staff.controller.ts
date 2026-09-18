import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClubActor } from '../club-access/club-access.service';
import {
  ClubActorGuard,
  ClubActorParam,
  ClubPermission,
} from '../club-access/club-actor.guard';
import { CoachPermission } from '../club-access/coach-permission.enum';
import { toClubView } from '../clubs/clubs.mapper';
import { ClubsService } from '../clubs/clubs.service';
import { UpdateClubProfileDto } from '../clubs/dto/update-club-profile.dto';
import { imageUploadOptions } from '../common/upload.config';
import { UserRole } from '../users/schemas/user.schema';

// The club profile editor, for whoever acts for the club: the club itself,
// or a coach on its staff (X-Club-Id). The club account keeps /clubs/me;
// this lives here rather than in ClubsModule because ClubsModule is what
// ClubAccessModule depends on, and it can't depend back.
@Controller('club/profile')
@UseGuards(JwtAuthGuard, RolesGuard, ClubActorGuard)
@Roles(UserRole.CLUB, UserRole.COACH)
export class ClubProfileAsStaffController {
  constructor(private readonly clubsService: ClubsService) {}

  // Reading needs only membership — it's the header of every club screen.
  @Get()
  async get(@ClubActorParam() actor: ClubActor) {
    return toClubView(
      await this.clubsService.getOrCreateForUser(actor.clubUserId),
    );
  }

  @Patch()
  @ClubPermission(CoachPermission.EDIT_CLUB_PROFILE)
  async update(
    @ClubActorParam() actor: ClubActor,
    @Body() dto: UpdateClubProfileDto,
  ) {
    return toClubView(
      await this.clubsService.updateProfile(actor.clubUserId, dto),
    );
  }

  @Post('logo')
  @ClubPermission(CoachPermission.EDIT_CLUB_PROFILE)
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async uploadLogo(
    @ClubActorParam() actor: ClubActor,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return toClubView(
      await this.clubsService.uploadLogo(actor.clubUserId, file),
    );
  }
}
