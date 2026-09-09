import { Controller, Get, UseGuards } from '@nestjs/common';
import { Roles } from '../../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { UserRole } from '../../users/schemas/user.schema';
import { StoreOverviewService } from './overview.service';

/// The dashboard's headline numbers. Admin-only and unpaginated — it is six
/// counts, computed by the database rather than by loading the collections.
@Controller('admin/store/overview')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminStoreOverviewController {
  constructor(private readonly overview: StoreOverviewService) {}

  @Get()
  summarise() {
    return this.overview.summarise();
  }
}
