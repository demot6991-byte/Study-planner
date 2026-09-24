import { Controller, Post, Body, Get, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { JwtService } from '../common/jwt.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly jwtService: JwtService,
  ) {}

  @Post('signup')
  async signUp(@Body() body: { email: string; password: string; name?: string }) {
    return this.authService.signUp(body.email, body.password, body.name);
  }

  @Post('signin')
  async signIn(@Body() body: { email: string; password: string }) {
    return this.authService.signIn(body.email, body.password);
  }

  @Post('signout')
  async signOut() {
    return { success: true };
  }

  @Post('refresh')
  async refresh(@Req() req: Request) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return { error: 'Missing token' };
    }
    const token = header.substring(7);
    const payload = this.jwtService.verify(token);
    if (!payload) {
      return { error: 'Invalid token' };
    }
    return this.authService.refreshToken(payload.sub, payload.email);
  }

  @Get('session')
  async getSession(@Req() req: Request) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return { user: null };
    }
    const token = header.substring(7);
    const payload = this.jwtService.verify(token);
    if (!payload) {
      return { user: null };
    }
    return this.authService.getSession(payload.sub);
  }
}
