import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../common/supabase.service';
import { JwtService } from '../common/jwt.service';
import bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly jwtService: JwtService,
  ) {}

  async signUp(email: string, password: string, name?: string) {
    if (!email || !password) {
      throw new BadRequestException('Email và mật khẩu là bắt buộc');
    }

    const { data: existing } = await this.supabaseService.serviceClient
      .from('users')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (existing) {
      throw new BadRequestException('Email đã được đăng ký');
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const { data, error } = await this.supabaseService.serviceClient
      .from('users')
      .insert({
        email,
        password_hash: passwordHash,
        name: name || '',
        academic_year: '2026-2027',
        semester: 1,
        timezone: 'Asia/Ho_Chi_Minh',
        week_starts_on: 'monday',
        onboarding_completed: false,
        has_sample_data: false,
      })
      .select('id, email, name, onboarding_completed, has_sample_data')
      .single();

    if (error || !data) {
      throw new BadRequestException(error?.message || 'Không thể tạo tài khoản');
    }

    const token = this.jwtService.sign({ sub: data.id, email: data.email });
    return { user: data, token };
  }

  async signIn(email: string, password: string) {
    if (!email || !password) {
      throw new BadRequestException('Email và mật khẩu là bắt buộc');
    }

    const { data, error } = await this.supabaseService.serviceClient
      .from('users')
      .select('id, email, name, password_hash, onboarding_completed, has_sample_data')
      .eq('email', email)
      .maybeSingle();

    if (error || !data) {
      throw new BadRequestException('Email hoặc mật khẩu không đúng');
    }

    const valid = await bcrypt.compare(password, data.password_hash);
    if (!valid) {
      throw new BadRequestException('Email hoặc mật khẩu không đúng');
    }

    const token = this.jwtService.sign({ sub: data.id, email: data.email });
    return {
      user: {
        id: data.id,
        email: data.email,
        name: data.name,
        onboarding_completed: data.onboarding_completed,
        has_sample_data: data.has_sample_data,
      },
      token,
    };
  }

  async getSession(userId: string) {
    const { data, error } = await this.supabaseService.serviceClient
      .from('users')
      .select('id, email, name, onboarding_completed, has_sample_data')
      .eq('id', userId)
      .maybeSingle();

    if (error || !data) {
      return { user: null };
    }

    return { user: data };
  }

  async refreshToken(userId: string, email: string) {
    const token = this.jwtService.sign({ sub: userId, email });
    return { token };
  }
}
