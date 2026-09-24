import { Controller, Post, Get, Req, Body, Query } from '@nestjs/common';
import { Request } from 'express';
import { SeedService } from './seed.service';
import { SupabaseService } from '../common/supabase.service';

interface SeedRequest extends Request {
  userId?: string;
}

@Controller('seed')
export class SeedController {
  constructor(
    private readonly seedService: SeedService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get('templates')
  async getTemplates() {
    const { data, error } = await this.supabaseService.serviceClient
      .from('sample_templates')
      .select('id, name, is_default')
      .order('is_default', { ascending: false });

    if (error) return { error: error.message };
    return { templates: data || [] };
  }

  @Get('template')
  async getTemplate(@Query('id') id: string) {
    const client = this.supabaseService.serviceClient;
    let query = client.from('sample_templates').select('id, name, template_data');
    if (id) {
      query = query.eq('id', id);
    } else {
      query = query.eq('is_default', true);
    }
    const { data, error } = await query.maybeSingle();
    if (error) return { error: error.message };
    return { template: data };
  }

  @Post()
  async seed(@Req() req: SeedRequest, @Body() body: { template_id?: string }) {
    if (!req.userId) {
      return { error: 'Not authenticated' };
    }
    return this.seedService.seedFromTemplate(req.userId, body?.template_id);
  }
}
