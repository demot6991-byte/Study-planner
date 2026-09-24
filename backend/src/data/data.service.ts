import { Injectable } from '@nestjs/common';
import type { SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class DataService {
  async loadAll(client: SupabaseClient, userId: string) {
    const [
      settingsRes,
      fixedRes,
      scheduleRes,
      subjectsRes,
      tasksRes,
      sessionsRes,
      journalRes,
      goalsRes,
      progressRes,
      configRes,
    ] = await Promise.all([
      client.from('settings').select('*').eq('user_id', userId).limit(1).maybeSingle(),
      client.from('fixed_activities').select('*').eq('user_id', userId).order('sort_order'),
      client.from('schedule_entries').select('*').eq('user_id', userId).order('weekday, sort_order'),
      client.from('study_subjects').select('*').eq('user_id', userId).order('sort_order'),
      client.from('tasks').select('*').eq('user_id', userId).order('due_date'),
      client.from('study_sessions').select('*').eq('user_id', userId).order('date, start_time'),
      client.from('journal_entries').select('*').eq('user_id', userId).order('entry_date', { ascending: false }).limit(30),
      client.from('weekly_goals').select('*').eq('user_id', userId),
      client.from('daily_progress').select('*').eq('user_id', userId).order('progress_date', { ascending: false }).limit(60),
      client.from('user_config').select('config_key, config_value').eq('user_id', userId),
    ]);

    const userConfig: Record<string, any> = {};
    for (const row of configRes.data || []) {
      userConfig[row.config_key] = row.config_value;
    }

    return {
      settings: settingsRes.data || null,
      fixedActivities: fixedRes.data || [],
      scheduleEntries: scheduleRes.data || [],
      subjects: subjectsRes.data || [],
      tasks: tasksRes.data || [],
      sessions: sessionsRes.data || [],
      journalEntries: journalRes.data || [],
      weeklyGoals: goalsRes.data || [],
      dailyProgress: progressRes.data || [],
      userConfig,
    };
  }
}
