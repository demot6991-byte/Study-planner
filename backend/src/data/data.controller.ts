import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';
import { DataService } from './data.service';
import type { SupabaseClient } from '@supabase/supabase-js';

interface DataRequest extends Request {
  userClient?: SupabaseClient;
}

@Controller('data')
export class DataController {
  constructor(private readonly dataService: DataService) {}

  @Get()
  async getAll(@Req() req: DataRequest) {
    if (!req.userClient) return { error: 'Not authenticated' };
    return this.dataService.loadAll(req.userClient);
  }
}
