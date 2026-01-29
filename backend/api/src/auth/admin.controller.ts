import { Controller, Get, Patch, Param, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AdminGuard } from './admin.guard';
import { Role } from './roles.enum';

@Controller('admin/users')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminUserController {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  @Get()
  async listUsers() {
    return this.userRepo.find({
      select: ['id', 'email', 'role'],
      order: { id: 'ASC' },
    });
  }

  @Patch(':id/promote')
  async promote(@Param('id') id: string) {
    const user = await this.userRepo.findOneBy({ id: Number(id) });
    if (!user) return { message: 'User not found' };

    user.role = Role.Admin;
    await this.userRepo.save(user);

    return { message: 'User promoted to admin' };
  }

  @Patch(':id/demote')
  async demote(@Param('id') id: string) {
    const user = await this.userRepo.findOneBy({ id: Number(id) });
    if (!user) return { message: 'User not found' };

    user.role = Role.Soldier;
    await this.userRepo.save(user);

    return { message: 'User demoted to soldier' };
  }
}
