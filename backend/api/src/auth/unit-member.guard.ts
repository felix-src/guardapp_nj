import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Role } from './roles.enum';
import type { AuthedRequest } from './auth-user';

/**
 * Use after JwtAuthGuard on routes with a unit `:id` param. Admins pass for
 * any unit; everyone else only for the unit they belong to (loaded from the
 * database by JwtAuthGuard, so a removal or transfer applies immediately).
 */
@Injectable()
export class UnitMemberGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const user = request.user;

    if (!user) return false;
    if (user.role === Role.Admin) return true;
    return user.unitId === Number(request.params.id);
  }
}
