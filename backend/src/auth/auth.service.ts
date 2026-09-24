import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../common/supabase.service';
import { JwtService } from '../common/jwt.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly jwtService: JwtService,
  ) {}

  async signUp(email: string, password: string) {
    if (!email || !password) {
      throw new BadRequestException('Email and password required');
    }
    const { data, error } = await this.supabaseService.client.auth.signUp({ email, password });
    if (error) {
      throw new BadRequestException(error.message);
    }
    if (!data.session) {
      return { user: { id: data.user.id, email: data.user.email || '' }, token: null };
    }
    const token = this.jwtService.sign({
      sub: data.user.id,
      email: data.user.email || '',
      supabase_access_token: data.session.access_token,
      supabase_refresh_token: data.session.refresh_token,
    });
    return {
      user: { id: data.user.id, email: data.user.email || '' },
      token,
      session: {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
      },
    };
  }

  async signIn(email: string, password: string) {
    if (!email || !password) {
      throw new BadRequestException('Email and password required');
    }
    const { data, error } = await this.supabaseService.client.auth.signInWithPassword({ email, password });
    if (error) {
      throw new BadRequestException(error.message);
    }
    const token = this.jwtService.sign({
      sub: data.user.id,
      email: data.user.email || '',
      supabase_access_token: data.session.access_token,
      supabase_refresh_token: data.session.refresh_token,
    });
    return {
      user: { id: data.user.id, email: data.user.email || '' },
      token,
      session: {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
      },
    };
  }

  async refreshToken(refreshToken: string) {
    if (!refreshToken) {
      throw new BadRequestException('Refresh token required');
    }
    const result = await this.supabaseService.refreshSession(refreshToken);
    if (!result) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    const token = this.jwtService.sign({
      sub: result.user.id,
      email: result.user.email,
      supabase_access_token: result.session.access_token,
      supabase_refresh_token: result.session.refresh_token,
    });
    return {
      user: result.user,
      token,
      session: result.session,
    };
  }

  async getGoogleUrl() {
    const supabaseUrl = process.env.SUPABASE_URL || '';
    const anonKey = process.env.SUPABASE_ANON_KEY || '';
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const callbackUrl = `${frontendUrl}/auth/callback`;
    const params = new URLSearchParams({
      client_id: anonKey,
      redirect_uri: `${supabaseUrl}/auth/v1/callback`,
      response_type: 'code',
      scope: 'openid profile email',
      flow: 'code',
      state: callbackUrl,
    });
    return { url: `${supabaseUrl}/auth/v1/authorize?provider=google&${params.toString()}` };
  }

  async exchangeCodeForSession(code: string) {
    if (!code) {
      throw new BadRequestException('Authorization code required');
    }
    try {
      const { data, error } = await this.supabaseService.client.auth.exchangeCodeForSession(code);
      if (error || !data.session) {
        throw new BadRequestException(error?.message || 'Failed to exchange code');
      }
      const token = this.jwtService.sign({
        sub: data.user.id,
        email: data.user.email || '',
        supabase_access_token: data.session.access_token,
        supabase_refresh_token: data.session.refresh_token,
      });
      return {
        user: { id: data.user.id, email: data.user.email || '' },
        token,
        session: {
          access_token: data.session.access_token,
          refresh_token: data.session.refresh_token,
        },
      };
    } catch (err: any) {
      if (err instanceof BadRequestException) throw err;
      throw new BadRequestException(err.message || 'Exchange failed');
    }
  }
}
