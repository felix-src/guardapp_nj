
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

@Controller('units')
export class UnitsController {
  constructor(private readonly unitsService: UnitsService) {}

  @Get()
  findAll() {
    return this.unitsService.findAll();
  }
 
  @Post() @UseGuards(JwtAuthGuard, AdminGuard)
  create(@Body() body: { name: string; state: string }) {
    return this.unitsService.create(body);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.unitsService.findOne(Number(id));
  }
}
