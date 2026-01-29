
import {
  Controller,
  Get,
  Param,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { UnitsService } from './units.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { Req } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';

@Controller('units')
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
  @UseGuards(JwtAuthGuard, AdminGuard)
  async create(@Body() body: { name: string; state: string }, @Req() req: any) {
    const unit = await this.unitsService.create(body);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'CREATE_UNIT',
      '/units',
    );

    return unit;
  }


  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.unitsService.findOne(Number(id));
  }
}
