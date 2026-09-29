import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  CRISIS_LINE,
  JOB_SECTIONS,
  NATIONAL_RESOURCES,
  NEW_JERSEY_RESOURCES,
} from './resources.data';

@Controller('resources')
@UseGuards(JwtAuthGuard)
export class ResourcesController {
  @Get()
  getResources() {
    return {
      crisisLine: CRISIS_LINE,
      newJersey: NEW_JERSEY_RESOURCES,
      national: NATIONAL_RESOURCES,
    };
  }

  @Get('jobs')
  getJobs() {
    return { sections: JOB_SECTIONS };
  }
}
