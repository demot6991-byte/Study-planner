import { Injectable } from '@nestjs/common';
import type { SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class OnboardingService {
  async getStatus(client: SupabaseClient, userId: string) {
    const { data, error } = await client
      .from('user_preferences')
      .select('onboarding_completed')
      .eq('user_id', userId)
      .maybeSingle();

    if (error || !data) {
      return { onboarding_completed: false };
    }
    return { onboarding_completed: data.onboarding_completed };
  }

  async markComplete(client: SupabaseClient, userId: string) {
    const { data: existing } = await client
      .from('user_preferences')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (existing) {
      const { error: updateError } = await client
        .from('user_preferences')
        .update({ onboarding_completed: true, updated_at: new Date().toISOString() })
        .eq('user_id', userId);
      if (updateError) {
        throw new Error(updateError.message);
      }
    } else {
      const { error: insertError } = await client
        .from('user_preferences')
        .insert({ user_id: userId, onboarding_completed: true });
      if (insertError) {
        throw new Error(insertError.message);
      }
    }

    return { success: true, onboarding_completed: true };
  }
}
