import { SetMetadata } from '@nestjs/common';
import { UserRole } from '../../users/schemas/user.schema';

export const ROLES_KEY = 'roles';

/** Restricts a route to the given roles — combine with JwtAuthGuard + RolesGuard. */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
