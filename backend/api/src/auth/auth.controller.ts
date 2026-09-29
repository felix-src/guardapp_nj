import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UseGuards, Req } from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from './jwt-auth.guard';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

// Per-IP rate limits (defaults in AppModule) against password and
// unit-code guessing.
@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // Public: checks a unit code and returns the unit's platoons/squads for
  // the sign-up form. Throttled like register since it reveals valid codes.
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
  login(@Body() body: LoginDto) {
    return this.authService.login(body.email, body.password);
  }

  // Role and unit are read fresh from the database, not from the JWT
  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: any) {
    return this.authService.getProfile(req.user.sub);
  }
}
