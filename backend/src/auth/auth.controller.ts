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
  async signUp(@Body() body: { email: string; password: string }) {
    return this.authService.signUp(body.email, body.password);
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
  async refresh(@Body() body: { refresh_token: string }) {
    return this.authService.refreshToken(body.refresh_token);
  }

  @Get('google-url')
  async getGoogleUrl() {
    return this.authService.getGoogleUrl();
  }

  @Post('google/callback')
  async googleCallback(@Body() body: { code: string }) {
    return this.authService.exchangeCodeForSession(body.code);
  }

  @Get('session')
  async getSession(@Req() req: Request) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return { user: null, session: null };
    }
    const token = header.substring(7);
    const payload = this.jwtService.verify(token);
    if (!payload) {
      return { user: null, session: null };
    }
    return { user: { id: payload.sub, email: payload.email } };
  }
}
