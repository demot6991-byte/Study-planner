import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from './jwt.service';
import { SupabaseService } from './supabase.service';
import type { SupabaseClient } from '@supabase/supabase-js';

export interface AuthedRequest extends Request {
  userId?: string;
  userEmail?: string;
  supabaseAccessToken?: string;
  supabaseRefreshToken?: string;
  userClient?: SupabaseClient;
}

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(
    private readonly jwtService: JwtService,
    private readonly supabaseService: SupabaseService,
  ) {}

  async use(req: AuthedRequest, _res: Response, next: NextFunction) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing authorization header');
    }

    const token = header.substring(7);
    const payload = this.jwtService.verify(token);
    if (!payload) {
      throw new UnauthorizedException('Invalid or expired token');
    }

    req.userId = payload.sub;
    req.userEmail = payload.email;
    req.supabaseAccessToken = payload.supabase_access_token;
    req.supabaseRefreshToken = payload.supabase_refresh_token;
    req.userClient = this.supabaseService.createUserClient(payload.supabase_access_token);

    next();
  }
}
