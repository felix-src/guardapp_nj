import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { UnitsService } from './units.service';

@Controller('units')
export class UnitsController {
  constructor(private readonly unitsService: UnitsService) {}

  @Get()
  findAll() {
    return this.unitsService.findAll();
  }
 
  @Post()
  create(@Body() body: { name: string; state: string }) {
    return this.unitsService.create(body);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.unitsService.findOne(Number(id));
  }
}
