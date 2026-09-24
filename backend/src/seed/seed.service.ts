import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../common/supabase.service';

const DAY_MAP: Record<string, number> = {
  sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6,
};

function parseTimeRange(time: string): { start: string; end: string } {
  const [start, end] = time.split('-');
  return { start: start?.trim() || '', end: end?.trim() || '' };
}

@Injectable()
export class SeedService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async seedFromTemplate(userId: string, templateId?: string) {
    const client = this.supabaseService.serviceClient;

    const { data: existingSettings } = await client
      .from('settings')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (existingSettings) {
      return { success: true, message: 'Already seeded' };
    }

    let template: any = null;
    if (templateId) {
      const { data } = await client
        .from('sample_templates')
        .select('template_data')
        .eq('id', templateId)
        .maybeSingle();
      template = data?.template_data;
    } else {
      const { data } = await client
        .from('sample_templates')
        .select('template_data')
        .eq('is_default', true)
        .maybeSingle();
      template = data?.template_data;
    }

    if (!template) {
      return { success: false, message: 'No template found' };
    }

    const t = template;
    const profile = t.profile || {};

    await client.from('settings').insert({
      user_id: userId,
      wake_time: profile.timezone ? '04:25' : '04:25',
      sleep_time: t.sleep_schedule?.sleep || '21:45',
      mass_time_start: '04:45',
      mass_time_end: '06:00',
      breakfast_start: '06:00',
      breakfast_end: '08:00',
      lunch_start: '11:30',
      lunch_end: '12:00',
      nap_start: '12:00',
      nap_end: '13:45',
      sports_start: '16:30',
      sports_end: '18:00',
      dinner_start: '18:00',
      dinner_end: '18:45',
      evening_prayer_time: '19:15',
      study_block1_start: '08:00',
      study_block1_end: '11:00',
      study_block2_start: '14:30',
      study_block2_end: '16:25',
      self_study_start: '19:30',
      self_study_end: '21:10',
      session_duration_min: 45,
      break_duration_min: 10,
      english_target_pct: t.goals?.english_ratio_target || 50,
      journal_min_min: t.goals?.journal_min_minutes_per_day || 15,
    });

    const fixedSchedule = t.fixed_daily_schedule || [];
    const activities = fixedSchedule.map((item: any, idx: number) => ({
      name: item.name,
      start_time: item.start,
      end_time: item.end,
      category: item.type || 'fixed',
      sort_order: idx + 1,
      user_id: userId,
    }));
    if (activities.length > 0) {
      await client.from('fixed_activities').insert(activities);
    }

    const personalSubjects = t.personal_study_subjects || [];
    const otherActivities = t.other_study_activities || [];
    const allSubjects = [...personalSubjects, ...otherActivities];

    const subjectsToInsert = allSubjects.map((s: any, idx: number) => ({
      name: s.name,
      code: s.id,
      color: this.getSubjectColor(s.id),
      icon_name: this.getSubjectIcon(s.id),
      is_in_english_ratio: (t.goals?.english_ratio_scope || []).includes(s.id),
      weekly_goal_min: s.weekly_target_minutes || 0,
      monthly_goal_min: s.monthly_target_minutes || 0,
      sort_order: idx + 1,
      user_id: userId,
      show_in_nav: s.category !== 'academic',
    }));
    if (subjectsToInsert.length > 0) {
      await client.from('study_subjects').insert(subjectsToInsert);
    }

    const classSchedule = t.official_class_schedule || [];
    const scheduleToInsert: any[] = [];
    let sortOrder = 0;
    for (const cls of classSchedule) {
      const weekday = DAY_MAP[cls.day] ?? 1;
      const { start, end } = parseTimeRange(cls.time);
      sortOrder++;
      scheduleToInsert.push({
        weekday,
        start_time: start,
        end_time: end,
        subject_name: cls.subject,
        session_type: 'class',
        teacher: cls.teacher || null,
        week_pattern: cls.week_pattern || null,
        period: cls.period || null,
        sort_order: sortOrder,
        user_id: userId,
      });
    }
    if (scheduleToInsert.length > 0) {
      await client.from('schedule_entries').insert(scheduleToInsert);
    }

    const planningRules = t.planning_rules || {};
    const configKeys: Record<string, any> = {
      goals: t.goals || {},
      planning_rules: planningRules,
      priority_rules: t.priority_rules || [],
      weekly_personal_study_plan: t.weekly_personal_study_plan || {},
      weekly_personal_study_target: t.weekly_personal_study_target || {},
      evening_study_slots: t.evening_study_slots || [],
      weekly_review: t.weekly_review || {},
      monthly_review: t.monthly_review || {},
      semester: t.semester || {},
      sleep_schedule: t.sleep_schedule || {},
    };

    const configRows = Object.entries(configKeys).map(([key, value]) => ({
      user_id: userId,
      config_key: key,
      config_value: value,
    }));
    if (configRows.length > 0) {
      await client.from('user_config').insert(configRows);
    }

    await client
      .from('users')
      .update({ has_sample_data: true, onboarding_completed: true, updated_at: new Date().toISOString() })
      .eq('id', userId);

    return { success: true, message: 'Sample data imported successfully' };
  }

  private getSubjectColor(code: string): string {
    const colors: Record<string, string> = {
      english: '#3b82f6',
      vietnamese_literature: '#10b981',
      instrument: '#f59e0b',
      reading: '#8b5cf6',
      review_homework: '#ef4444',
      spiritual_journal: '#ec4899',
    };
    return colors[code] || '#6b7280';
  }

  private getSubjectIcon(code: string): string {
    const icons: Record<string, string> = {
      english: 'Languages',
      vietnamese_literature: 'PenLine',
      instrument: 'Music',
      reading: 'BookMarked',
      review_homework: 'GraduationCap',
      spiritual_journal: 'Heart',
    };
    return icons[code] || 'BookOpen';
  }
}
