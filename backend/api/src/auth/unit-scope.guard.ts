import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Role } from './roles.enum';
import type { AuthedRequest } from './auth-user';

/**
 * Use after JwtAuthGuard on routes with a unit `:id` param. Admins pass for
 * any unit; a Readiness NCO passes only for their own unit. JwtAuthGuard
 * loads role and unit from the database, so a demotion or transfer takes
 * effect immediately.
 */
@Injectable()
export class UnitScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const user = request.user;

    if (!user) return false;
    if (user.role === Role.Admin) return true;
    return (
      user.role === Role.ReadinessNco &&
      user.unitId === Number(request.params.id)
    );
  }
}
