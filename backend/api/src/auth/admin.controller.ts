import { Controller, Get, Patch, Param, UseGuards, Req } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AdminGuard } from './admin.guard';
import { Role } from './roles.enum';
import { AuditService } from '../audit/audit.service';

@Controller('admin/users')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminUserController {
  constructor(
  @InjectRepository(User)
  private readonly userRepo: Repository<User>,
  private readonly auditService: AuditService,
) {}


  @Get()
  async listUsers() {
    return this.userRepo.find({
      select: ['id', 'email', 'role'],
      order: { id: 'ASC' },
    });
  }

   @Patch(':id/promote')
  async promote(@Param('id') id: string, @Req() req: any) {
    const user = await this.userRepo.findOneBy({ id: Number(id) });
    if (!user) return { message: 'User not found' };

    user.role = Role.Admin;
    await this.userRepo.save(user);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'PROMOTE_USER',
      `/admin/users/${id}/promote`,
    );

    return { message: 'User promoted to admin' };
  }

    @Patch(':id/demote')
  async demote(@Param('id') id: string, @Req() req: any) {
    const user = await this.userRepo.findOneBy({ id: Number(id) });
    if (!user) return { message: 'User not found' };

    user.role = Role.Soldier;
    await this.userRepo.save(user);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'DEMOTE_USER',
      `/admin/users/${id}/demote`,
    );

    return { message: 'User demoted to soldier' };
  }

}
