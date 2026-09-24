import {
  Controller, Get, Post, Put, Delete,
  Req, Query, Body, Param, BadRequestException,
} from '@nestjs/common';
import { Request } from 'express';
import { CrudService } from './crud.service';
import type { SupabaseClient } from '@supabase/supabase-js';

interface CrudRequest extends Request {
  userClient?: SupabaseClient;
  userId?: string;
}

@Controller()
export class CrudController {
  constructor(private readonly crudService: CrudService) {}

  @Get(':table')
  async getAll(
    @Param('table') table: string,
    @Query() query: any,
    @Req() req: CrudRequest,
  ) {
    if (!req.userClient) throw new BadRequestException('Not authenticated');
    return this.crudService.getAll(table, query, req.userClient);
  }

  @Post(':table')
  async insert(
    @Param('table') table: string,
    @Body() body: any,
    @Req() req: CrudRequest,
  ) {
    if (!req.userClient) throw new BadRequestException('Not authenticated');
    return this.crudService.insert(table, body, req.userClient);
  }

  @Put(':table')
  async update(
    @Param('table') table: string,
    @Query() query: any,
    @Body() body: any,
    @Req() req: CrudRequest,
  ) {
    if (!req.userClient) throw new BadRequestException('Not authenticated');
    return this.crudService.update(table, query, body, req.userClient);
  }

  @Delete(':table')
  async remove(
    @Param('table') table: string,
    @Query() query: any,
    @Req() req: CrudRequest,
  ) {
    if (!req.userClient) throw new BadRequestException('Not authenticated');
    return this.crudService.remove(table, query, req.userClient);
  }
}
