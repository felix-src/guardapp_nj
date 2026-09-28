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
  Req,
} from '@nestjs/common';
import { UnitsService } from './units.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { UnitScopeGuard } from '../auth/unit-scope.guard';
import { AuditService } from '../audit/audit.service';
import { CreateUnitDto } from './dto/create-unit.dto';
import { CreateContactDto } from './dto/create-contact.dto';

@Controller('units')
@UseGuards(JwtAuthGuard)
export class UnitsController {
  constructor(
    private readonly unitsService: UnitsService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  findAll() {
    return this.unitsService.findAll();
  }

  @Post()
  @UseGuards(AdminGuard)
  async create(@Body() body: CreateUnitDto, @Req() req: any) {
    const unit = await this.unitsService.create(body);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'CREATE_UNIT',
      '/units',
    );

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
    @Req() req: any,
  ) {
    const contact = await this.unitsService.addContact(id, body);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
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
    @Req() req: any,
  ) {
    await this.unitsService.removeContact(id, contactId);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
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
  async rotateJoinCode(@Param('id', ParseIntPipe) id: number, @Req() req: any) {
    const result = await this.unitsService.rotateJoinCode(id);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
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
    @Req() req: any,
  ) {
    await this.unitsService.removeMember(id, userId);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'REMOVE_UNIT_MEMBER',
      `/units/${id}/members/${userId}`,
    );
  }
}
