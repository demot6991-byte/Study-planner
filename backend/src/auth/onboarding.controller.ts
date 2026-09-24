import { Controller, Get, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { OnboardingService } from './onboarding.service';

interface OnboardingRequest extends Request {
  userId?: string;
}

@Controller('auth/onboarding')
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Get()
  async getStatus(@Req() req: OnboardingRequest) {
    if (!req.userId) {
      return { onboarding_completed: false, has_sample_data: false };
    }
    return this.onboardingService.getStatus(req.userId);
  }

  @Post('complete')
  async complete(@Req() req: OnboardingRequest) {
    if (!req.userId) {
      return { error: 'Not authenticated' };
    }
    return this.onboardingService.markComplete(req.userId);
  }
}
