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
  @UseGuards(AdminGuard)
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
  @UseGuards(AdminGuard)
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
}
