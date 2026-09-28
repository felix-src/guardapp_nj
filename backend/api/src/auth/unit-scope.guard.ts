import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { Role } from './roles.enum';

/**
 * Use after JwtAuthGuard on routes with a unit `:id` param. Admins pass for
 * any unit; a Readiness NCO passes only for their own unit. The NCO's role
 * and unit are re-read from the database so a demotion or transfer takes
 * effect immediately instead of when their JWT expires.
 */
@Injectable()
export class UnitScopeGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) return false;
    if (user.role === Role.Admin) return true;
    if (user.role !== Role.ReadinessNco) return false;

    const current = await this.userRepo.findOneBy({ id: user.sub });
    return (
      current?.role === Role.ReadinessNco &&
      current.unitId === Number(request.params.id)
    );
  }
}
