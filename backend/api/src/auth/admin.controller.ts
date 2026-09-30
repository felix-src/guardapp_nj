import {
  Body,
  Controller,
  Get,
  HttpCode,
  NotFoundException,
  Patch,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AdminGuard } from './admin.guard';
import { Role } from './roles.enum';
import { CurrentUser } from './current-user.decorator';
import type { AuthUser } from './auth-user';
import { AuthService } from './auth.service';
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
    private readonly authService: AuthService,
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
        'lockedUntil',
      ],
      order: { id: 'ASC' },
    });
  }

  @Patch(':id/promote')
  async promote(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() admin: AuthUser,
  ) {
    await this.setRole(id, Role.Admin);
    await this.auditService.log(
      admin.id,
      admin.role,
      'PROMOTE_USER',
      `/admin/users/${id}/promote`,
    );
    return { message: 'User promoted to admin' };
  }

  @Patch(':id/demote')
  async demote(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() admin: AuthUser,
  ) {
    await this.setRole(id, Role.Soldier);
    await this.auditService.log(
      admin.id,
      admin.role,
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
    @CurrentUser() admin: AuthUser,
  ) {
    const user = await this.userRepo.findOneBy({ id });
    if (!user) throw new NotFoundException('User not found');
    await this.unitsService.ensureUnitExists(body.unitId);

    if (user.unitId !== body.unitId) {
      // Their old position belongs to the old unit's chart
      user.orgElementId = null;
      user.dutyRole = null;
    }
    user.role = Role.ReadinessNco;
    user.unitId = body.unitId;
    await this.userRepo.save(user);

    await this.auditService.log(
      admin.id,
      admin.role,
      'ASSIGN_READINESS_NCO',
      `/admin/users/${id}/readiness-nco`,
    );

    return { message: 'User is now Readiness NCO', unitId: body.unitId };
  }

  // Lost or stolen phone: sign the account out on every device
  @Post(':id/revoke-sessions')
  @HttpCode(204)
  async revokeSessions(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() admin: AuthUser,
  ) {
    await this.authService.revokeSessions(id);
    await this.auditService.log(
      admin.id,
      admin.role,
      'REVOKE_SESSIONS',
      `/admin/users/${id}/revoke-sessions`,
    );
  }

  private async setRole(id: number, role: Role) {
    const result = await this.userRepo.update(id, { role });
    if (!result.affected) throw new NotFoundException('User not found');
  }
}
