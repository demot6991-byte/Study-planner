import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../common/supabase.service';

@Injectable()
export class OnboardingService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getStatus(userId: string) {
    const { data, error } = await this.supabaseService.serviceClient
      .from('users')
      .select('onboarding_completed, has_sample_data')
      .eq('id', userId)
      .maybeSingle();

    if (error || !data) {
      return { onboarding_completed: false, has_sample_data: false };
    }
    return {
      onboarding_completed: data.onboarding_completed,
      has_sample_data: data.has_sample_data,
    };
  }

  async markComplete(userId: string) {
    const { error } = await this.supabaseService.serviceClient
      .from('users')
      .update({ onboarding_completed: true, updated_at: new Date().toISOString() })
      .eq('id', userId);

    if (error) {
      throw new Error(error.message);
    }

    return { success: true, onboarding_completed: true };
  }
}
