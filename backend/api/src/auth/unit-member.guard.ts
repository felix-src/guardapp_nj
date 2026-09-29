import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { Role } from './roles.enum';

/**
 * Use after JwtAuthGuard on routes with a unit `:id` param. Admins pass for
 * any unit; everyone else only for the unit they belong to (read from the
 * database, so a removal or transfer takes effect immediately).
 */
@Injectable()
export class UnitMemberGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) return false;
    if (user.role === Role.Admin) return true;

    const current = await this.userRepo.findOneBy({ id: user.sub });
    return current?.unitId === Number(request.params.id);
  }
}
