import { Injectable } from '@nestjs/common';
import jwt from 'jsonwebtoken';

export interface JwtPayload {
  sub: string;
  email: string;
  supabase_access_token: string;
  supabase_refresh_token: string;
}

@Injectable()
export class JwtService {
  private readonly secret: string;
  private readonly expiresIn: string;

  constructor() {
    this.secret = process.env.JWT_SECRET || '';
    if (!this.secret) {
      throw new Error('JWT_SECRET is not set');
    }
    this.expiresIn = '8h';
  }

  sign(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.expiresIn } as jwt.SignOptions);
  }

  verify(token: string): JwtPayload | null {
    try {
      const decoded = jwt.verify(token, this.secret) as JwtPayload;
      return decoded;
    } catch {
      return null;
    }
  }
}
