
import { UnitsService } from './units.service';
import { Controller, Get, Param, Post, Body, UseGuards } from '@nestjs/common';
import { RolesGuard } from '../auth/roles.guard';

@Controller('units')
export class UnitsController {
  constructor(private readonly unitsService: UnitsService) {}

  @Get()
  findAll() {
    return this.unitsService.findAll();
  }
 
  @Post() @UseGuards(RolesGuard)
  create(@Body() body: { name: string; state: string }) {
    return this.unitsService.create(body);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.unitsService.findOne(Number(id));
  }
}
