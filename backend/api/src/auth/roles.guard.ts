import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
} from '@nestjs/common';
import { Role } from './roles.enum';

@Injectable()
export class RolesGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();

    const role = request.headers['x-role'];

    if (!role) {
      throw new ForbiddenException('No role provided');
    }

    if (role !== Role.Admin) {
      throw new ForbiddenException('Admin role required');
    }

    return true;
  }
}
