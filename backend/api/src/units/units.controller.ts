import {
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Delete,
  Body,
  HttpCode,
  UseGuards,
} from '@nestjs/common';
import { UnitsService } from './units.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { UnitScopeGuard } from '../auth/unit-scope.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/auth-user';
import { AuthService } from '../auth/auth.service';
import { AuditService } from '../audit/audit.service';
import { CreateUnitDto } from './dto/create-unit.dto';
import { CreateContactDto } from './dto/create-contact.dto';

@Controller('units')
@UseGuards(JwtAuthGuard)
export class UnitsController {
  constructor(
    private readonly unitsService: UnitsService,
    private readonly authService: AuthService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  findAll() {
    return this.unitsService.findAll();
  }

  @Post()
  @UseGuards(AdminGuard)
  async create(@Body() body: CreateUnitDto, @CurrentUser() user: AuthUser) {
    const unit = await this.unitsService.create(body);

    await this.auditService.log(user.id, user.role, 'CREATE_UNIT', '/units');

    return unit;
  }

  // Unit with its points of contact
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.unitsService.findOne(id);
  }

  @Get(':id/contacts')
  findContacts(@Param('id', ParseIntPipe) id: number) {
    return this.unitsService.findContacts(id);
  }

  @Post(':id/contacts')
  @UseGuards(UnitScopeGuard)
  async addContact(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: CreateContactDto,
    @CurrentUser() user: AuthUser,
  ) {
    const contact = await this.unitsService.addContact(id, body);

    await this.auditService.log(
      user.id,
      user.role,
      'CREATE_UNIT_CONTACT',
      `/units/${id}/contacts`,
    );

    return contact;
  }

  @Delete(':id/contacts/:contactId')
  @UseGuards(UnitScopeGuard)
  @HttpCode(204)
  async removeContact(
    @Param('id', ParseIntPipe) id: number,
    @Param('contactId', ParseIntPipe) contactId: number,
    @CurrentUser() user: AuthUser,
  ) {
    await this.unitsService.removeContact(id, contactId);

    await this.auditService.log(
      user.id,
      user.role,
      'DELETE_UNIT_CONTACT',
      `/units/${id}/contacts/${contactId}`,
    );
  }

  // Current sign-up code and link; rotates automatically once a week
  @Get(':id/join-code')
  @UseGuards(UnitScopeGuard)
  getJoinCode(@Param('id', ParseIntPipe) id: number) {
    return this.unitsService.getJoinCode(id);
  }

  // Replace the code now, e.g. if a link was shared outside the unit
  @Post(':id/join-code/rotate')
  @UseGuards(UnitScopeGuard)
  async rotateJoinCode(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: AuthUser,
  ) {
    const result = await this.unitsService.rotateJoinCode(id);

    await this.auditService.log(
      user.id,
      user.role,
      'ROTATE_JOIN_CODE',
      `/units/${id}/join-code/rotate`,
    );

    return result;
  }

  @Get(':id/members')
  @UseGuards(UnitScopeGuard)
  listMembers(@Param('id', ParseIntPipe) id: number) {
    return this.unitsService.listMembers(id);
  }

  @Delete(':id/members/:userId')
  @UseGuards(UnitScopeGuard)
  @HttpCode(204)
  async removeMember(
    @Param('id', ParseIntPipe) id: number,
    @Param('userId', ParseIntPipe) userId: number,
    @CurrentUser() user: AuthUser,
  ) {
    await this.unitsService.removeMember(id, userId);

    await this.auditService.log(
      user.id,
      user.role,
      'REMOVE_UNIT_MEMBER',
      `/units/${id}/members/${userId}`,
    );
  }

  // Lost or stolen phone: sign a member out on every device
  @Post(':id/members/:userId/revoke-sessions')
  @UseGuards(UnitScopeGuard)
  @HttpCode(204)
  async revokeMemberSessions(
    @Param('id', ParseIntPipe) id: number,
    @Param('userId', ParseIntPipe) userId: number,
    @CurrentUser() user: AuthUser,
  ) {
    await this.unitsService.ensureMember(id, userId);
    await this.authService.revokeSessions(userId);

    await this.auditService.log(
      user.id,
      user.role,
      'REVOKE_MEMBER_SESSIONS',
      `/units/${id}/members/${userId}/revoke-sessions`,
    );
  }
}
