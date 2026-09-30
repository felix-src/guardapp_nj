import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Role } from './roles.enum';
import type { AuthedRequest } from './auth-user';

/** Use after JwtAuthGuard, which loads the role from the database. */
@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const user = context.switchToHttp().getRequest<AuthedRequest>().user;
    return user?.role === Role.Admin;
  }
}
