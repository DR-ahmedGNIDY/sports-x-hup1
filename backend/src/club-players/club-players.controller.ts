import {
  Body,
  Controller,
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
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { imageUploadOptions } from '../common/upload.config';
import { UpdatePlayerProfileDto } from '../players/dto/update-player-profile.dto';
import { UploadMediaDto } from '../players/dto/upload-media.dto';
import { toOwnerView } from '../players/players.mapper';
import { UserRole } from '../users/schemas/user.schema';
import { ClubPlayersService } from './club-players.service';
import { CreateClubPlayerDto } from './dto/create-club-player.dto';

@Controller('club-players')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CLUB)
export class ClubPlayersController {
  constructor(private readonly clubPlayersService: ClubPlayersService) {}

  @Post()
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateClubPlayerDto,
  ) {
    const { player, credentials, dialCode } =
      await this.clubPlayersService.createPlayer(user.sub, dto);
    return { player: { ...toOwnerView(player), dialCode }, credentials };
  }

  @Get()
  async list(@CurrentUser() user: JwtPayload) {
    const rows = await this.clubPlayersService.listForClub(user.sub);
    return rows
      .filter((row) => row.profile !== null)
      .map((row) => ({
        ...toOwnerView(row.profile!),
        dialCode: row.ownership.dialCode,
      }));
  }

  @Get(':playerId')
  async getOne(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.getOneForClub(
      user.sub,
      playerId,
    );
    return { ...toOwnerView(profile), dialCode };
  }

  @Patch(':playerId')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
    @Body() dto: UpdatePlayerProfileDto,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.updatePlayer(
      user.sub,
      playerId,
      dto,
    );
    return { ...toOwnerView(profile), dialCode };
  }

  @Post(':playerId/photo')
  @UseInterceptors(FileInterceptor('file', imageUploadOptions))
  async uploadPhoto(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadMediaDto,
  ) {
    const { profile, dialCode } = await this.clubPlayersService.uploadPhoto(
      user.sub,
      playerId,
      file,
      dto.isProfilePhoto ?? false,
    );
    return { ...toOwnerView(profile), dialCode };
  }

  @Post(':playerId/resend-credentials')
  async resendCredentials(
    @CurrentUser() user: JwtPayload,
    @Param('playerId') playerId: string,
  ) {
    const credentials = await this.clubPlayersService.resendCredentials(
      user.sub,
      playerId,
    );
    return { credentials };
  }
}
