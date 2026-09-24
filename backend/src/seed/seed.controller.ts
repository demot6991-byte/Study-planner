import { Controller, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { SeedService } from './seed.service';
import type { SupabaseClient } from '@supabase/supabase-js';

interface SeedRequest extends Request {
  userClient?: SupabaseClient;
  userId?: string;
}

@Controller('seed')
export class SeedController {
  constructor(private readonly seedService: SeedService) {}

  @Post()
  async seed(@Req() req: SeedRequest) {
    if (!req.userClient || !req.userId) {
      return { error: 'Not authenticated' };
    }
    return this.seedService.seedDefaultData(req.userClient, req.userId);
  }
}
