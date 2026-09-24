import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';
import { DataService } from './data.service';

interface DataRequest extends Request {
  userClient?: any;
  userId?: string;
}

@Controller('data')
export class DataController {
  constructor(private readonly dataService: DataService) {}

  @Get()
  async getAll(@Req() req: DataRequest) {
    if (!req.userClient || !req.userId) return { error: 'Not authenticated' };
    return this.dataService.loadAll(req.userClient, req.userId);
  }
}
