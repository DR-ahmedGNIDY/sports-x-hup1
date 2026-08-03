import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import {
  CurrentUser,
  JwtPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';
import { toPublicUser } from './users.mapper';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async me(@CurrentUser() user: JwtPayload) {
    const found = await this.usersService.findByIdOrThrow(user.sub);
    return toPublicUser(found);
  }

  @Patch('me')
  async updateMe(@CurrentUser() user: JwtPayload, @Body() dto: UpdateUserDto) {
    const updated = await this.usersService.updateAccount(user.sub, dto);
    return toPublicUser(updated);
  }
}
