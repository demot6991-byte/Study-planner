import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from './jwt.service';
import type { SupabaseClient } from '@supabase/supabase-js';
import { SupabaseService } from './supabase.service';

export interface AuthedRequest extends Request {
  userId?: string;
  userEmail?: string;
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
    req.userClient = this.supabaseService.getUserClient(payload.sub);

    next();
  }
}
