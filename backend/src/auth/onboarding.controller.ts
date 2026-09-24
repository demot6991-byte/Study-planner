import { Controller, Get, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { OnboardingService } from './onboarding.service';
import type { SupabaseClient } from '@supabase/supabase-js';

interface OnboardingRequest extends Request {
  userClient?: SupabaseClient;
  userId?: string;
}

@Controller('auth/onboarding')
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Get()
  async getStatus(@Req() req: OnboardingRequest) {
    if (!req.userClient || !req.userId) {
      return { onboarding_completed: false };
    }
    return this.onboardingService.getStatus(req.userClient, req.userId);
  }

  @Post('complete')
  async complete(@Req() req: OnboardingRequest) {
    if (!req.userClient || !req.userId) {
      return { error: 'Not authenticated' };
    }
    return this.onboardingService.markComplete(req.userClient, req.userId);
  }
}
