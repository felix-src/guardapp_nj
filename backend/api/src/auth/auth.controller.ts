import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';
import { LoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() body: { email: string; password: string }) {
    return this.authService.register(body.email, body.password);
  }

  @Post('login')
  async login(@Body() body: LoginDto) {
    console.log('LOGIN BODY:', body);
    const result = await this.authService.login(
      body.email,
      body.password,
    );

    if (!result) {
      return { message: 'Invalid credentials' };
    }

    return result;
  }

    @Post('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: any) {
    return {
      userId: req.user.sub,
      role: req.user.role,
    };
  }

}
