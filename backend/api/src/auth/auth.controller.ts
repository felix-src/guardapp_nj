import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { CurrentUser } from './current-user.decorator';
import type { AuthUser } from './auth-user';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { AuditService } from '../audit/audit.service';

// Tighter per-IP limits than the global default (see AppModule), against
// password and unit-code guessing.
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly auditService: AuditService,
  ) {}

  // Public: checks a unit code and returns the unit's platoons/squads for
  // the sign-up form. Throttled since it reveals whether a code is valid.
  @Get('join/:code')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  lookupJoinCode(@Param('code') code: string) {
    return this.authService.lookupJoinCode(code);
  }

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  register(@Body() body: RegisterDto) {
    return this.authService.register(body);
  }

  @Post('login')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  login(@Body() body: LoginDto) {
    return this.authService.login(body.email, body.password);
  }

  // Role and unit are read fresh from the database, not from the token
  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: AuthUser) {
    return this.authService.getProfile(user.id);
  }

  // Signs this account out on every device (e.g. a lost phone)
  @Post('logout-all')
  @UseGuards(JwtAuthGuard)
  @HttpCode(204)
  async logoutAll(@CurrentUser() user: AuthUser) {
    await this.authService.revokeSessions(user.id);
    await this.auditService.log(
      user.id,
      user.role,
      'LOGOUT_ALL_DEVICES',
      '/auth/logout-all',
    );
  }

  // Returns a new token for this device; all other devices are signed out
  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @HttpCode(200)
  changePassword(
    @CurrentUser() user: AuthUser,
    @Body() body: ChangePasswordDto,
  ) {
    return this.authService.changePassword(
      user.id,
      body.currentPassword,
      body.newPassword,
    );
  }
}
