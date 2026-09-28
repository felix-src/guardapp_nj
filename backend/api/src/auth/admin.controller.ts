import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Patch,
  Param,
  ParseIntPipe,
  UseGuards,
  Req,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AdminGuard } from './admin.guard';
import { Role } from './roles.enum';
import { AuditService } from '../audit/audit.service';
import { UnitsService } from '../units/units.service';
import { AssignNcoDto } from './dto/assign-nco.dto';

@Controller('admin/users')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminUserController {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly auditService: AuditService,
    private readonly unitsService: UnitsService,
  ) {}

  @Get()
  async listUsers() {
    return this.userRepo.find({
      select: [
        'id',
        'email',
        'role',
        'firstName',
        'lastName',
        'rank',
        'unitId',
      ],
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

  // Make a user the Readiness NCO for a unit (moves them into that unit)
  @Patch(':id/readiness-nco')
  async makeReadinessNco(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: AssignNcoDto,
    @Req() req: any,
  ) {
    const user = await this.userRepo.findOneBy({ id });
    if (!user) throw new NotFoundException('User not found');
    await this.unitsService.ensureUnitExists(body.unitId);

    user.role = Role.ReadinessNco;
    user.unitId = body.unitId;
    await this.userRepo.save(user);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'ASSIGN_READINESS_NCO',
      `/admin/users/${id}/readiness-nco`,
    );

    return { message: 'User is now Readiness NCO', unitId: body.unitId };
  }
}
