import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UnitMemberGuard } from '../auth/unit-member.guard';
import { UnitScopeGuard } from '../auth/unit-scope.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/auth-user';
import { AuditService } from '../audit/audit.service';
import { OrgService } from './org.service';
import { CreateOrgElementDto } from './dto/create-org-element.dto';
import { RenameOrgElementDto } from './dto/rename-org-element.dto';
import { SetPositionDto } from './dto/set-position.dto';

// Platoons, squads, and who holds which position in a unit
@Controller('units')
@UseGuards(JwtAuthGuard)
export class OrgController {
  constructor(
    private readonly orgService: OrgService,
    private readonly auditService: AuditService,
  ) {}

  // Anyone in the unit can open it; what they see depends on their
  // position (need-to-know, see org-visibility.ts)
  @Get(':id/org-chart')
  @UseGuards(UnitMemberGuard)
  getOrgChart(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: AuthUser,
  ) {
    return this.orgService.getOrgChart(id, user);
  }

  @Post(':id/org-elements')
  @UseGuards(UnitScopeGuard)
  async addElement(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: CreateOrgElementDto,
    @CurrentUser() user: AuthUser,
  ) {
    const element = await this.orgService.addElement(id, body);

    await this.auditService.log(
      user.id,
      user.role,
      'CREATE_ORG_ELEMENT',
      `/units/${id}/org-elements`,
    );

    return element;
  }

  @Patch(':id/org-elements/:elementId')
  @UseGuards(UnitScopeGuard)
  async renameElement(
    @Param('id', ParseIntPipe) id: number,
    @Param('elementId', ParseIntPipe) elementId: number,
    @Body() body: RenameOrgElementDto,
    @CurrentUser() user: AuthUser,
  ) {
    const element = await this.orgService.renameElement(
      id,
      elementId,
      body.name,
    );

    await this.auditService.log(
      user.id,
      user.role,
      'RENAME_ORG_ELEMENT',
      `/units/${id}/org-elements/${elementId}`,
    );

    return element;
  }

  @Delete(':id/org-elements/:elementId')
  @UseGuards(UnitScopeGuard)
  @HttpCode(204)
  async deleteElement(
    @Param('id', ParseIntPipe) id: number,
    @Param('elementId', ParseIntPipe) elementId: number,
    @CurrentUser() user: AuthUser,
  ) {
    await this.orgService.deleteElement(id, elementId);

    await this.auditService.log(
      user.id,
      user.role,
      'DELETE_ORG_ELEMENT',
      `/units/${id}/org-elements/${elementId}`,
    );
  }

  // Fix a soldier's platoon/squad/duty role
  @Patch(':id/members/:userId/position')
  @UseGuards(UnitScopeGuard)
  async setPosition(
    @Param('id', ParseIntPipe) id: number,
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: SetPositionDto,
    @CurrentUser() user: AuthUser,
  ) {
    await this.orgService.setMemberPosition(
      id,
      userId,
      body.orgElementId,
      body.dutyRole,
    );

    await this.auditService.log(
      user.id,
      user.role,
      'SET_MEMBER_POSITION',
      `/units/${id}/members/${userId}/position`,
    );

    return { message: 'Position updated' };
  }
}
