/*
# Custom User Authentication + Sample Data Template

## Overview
Migrates from Supabase Auth to a custom users table for full database-managed
authentication. Adds sample data template storage and per-user configuration.

## New Tables
1. **users** — custom auth table with email, password_hash, and profile fields
2. **user_config** — per-user JSON configuration (goals, planning rules, etc.)
3. **sample_templates** — reusable data templates that users can import

## Modified Tables
- All 16 data tables: FK on user_id changed from auth.users to users table
- schedule_entries: added teacher and week_pattern columns
- All data tables: removed DEFAULT auth.uid() from user_id

## Security
- RLS enabled on new tables (accessible only via service role key)
- Backend uses service role key (bypasses RLS) with app-level user_id filtering
- Existing RLS policies on data tables remain but are inert since auth.uid()
  is always NULL without Supabase Auth — service role bypasses RLS entirely
*/

-- ============================================================
-- 1. USERS — custom authentication table
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  name text NOT NULL DEFAULT '',
  academic_year text,
  semester int,
  location text,
  class_size int,
  timezone text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  week_starts_on text NOT NULL DEFAULT 'monday',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. USER_CONFIG — per-user JSON configuration
-- ============================================================
CREATE TABLE IF NOT EXISTS user_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  config_key text NOT NULL,
  config_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, config_key)
);

ALTER TABLE user_config ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 3. SAMPLE_TEMPLATES — reusable data templates
-- ============================================================
CREATE TABLE IF NOT EXISTS sample_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  template_data jsonb NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE sample_templates ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. MIGRATE FK CONSTRAINTS FROM auth.users TO users
-- ============================================================
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'settings', 'fixed_activities', 'schedule_entries', 'study_subjects',
    'tasks', 'study_sessions', 'journal_entries', 'books',
    'instrument_practices', 'weekly_goals', 'monthly_goals',
    'semester_goals', 'daily_progress', 'weekly_reviews',
    'monthly_reviews', 'user_preferences'
  ];
  constraint_name text;
BEGIN
  FOREACH t IN ARRAY tables LOOP
    constraint_name := t || '_user_id_fkey';

    -- Drop existing FK to auth.users
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', t, constraint_name);

    -- Remove DEFAULT auth.uid()
    EXECUTE format('ALTER TABLE %I ALTER COLUMN user_id DROP DEFAULT', t);

    -- Add new FK to users table (NOT VALID so existing rows aren't checked)
    BEGIN
      EXECUTE format(
        'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID',
        t, constraint_name
      );
    EXCEPTION WHEN duplicate_object THEN
      NULL;
    END;
  END LOOP;
END $$;

-- ============================================================
-- 5. ADD COLUMNS TO schedule_entries
-- ============================================================
ALTER TABLE schedule_entries
  ADD COLUMN IF NOT EXISTS teacher text,
  ADD COLUMN IF NOT EXISTS week_pattern text,
  ADD COLUMN IF NOT EXISTS period int;

-- ============================================================
-- 6. ADD onboarding_completed TO users TABLE
--    (replaces user_preferences for custom auth)
-- ============================================================
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onboarding_completed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS has_sample_data boolean NOT NULL DEFAULT false;

-- ============================================================
-- 7. INSERT DEFAULT SAMPLE TEMPLATE
-- ============================================================
INSERT INTO sample_templates (name, template_data, is_default)
SELECT 'Mẫu dữ liệu thỉnh sinh', (
  '{
    "profile": {
      "name": "Thỉnh sinh 1",
      "academic_year": "2026-2027",
      "semester": 1,
      "location": "Phòng học chung 1 (Lầu 1)",
      "class_size": 5,
      "timezone": "Asia/Ho_Chi_Minh",
      "week_starts_on": "monday"
    },
    "goals": {
      "main_goal": "Xây dựng thói quen học tập, rèn luyện và đời sống thiêng liêng ổn định",
      "english_ratio_target": 50,
      "english_ratio_scope": ["english", "vietnamese_literature", "instrument", "reading"],
      "journal_min_minutes_per_day": 15
    },
    "sleep_schedule": {
      "wake_up": "04:25",
      "prepare_for_sleep": "21:35",
      "sleep": "21:45"
    },
    "fixed_daily_schedule": [
      {"id": "wake_up", "name": "Thức dậy", "start": "04:25", "end": "04:45", "type": "fixed", "priority": 1},
      {"id": "mass", "name": "Thánh lễ", "start": "04:45", "end": "06:00", "type": "spiritual", "priority": 1},
      {"id": "breakfast_work_common", "name": "Ăn sáng + lao tác + sinh hoạt chung", "start": "06:00", "end": "08:00", "type": "community", "priority": 1},
      {"id": "morning_prayer", "name": "Kinh trưa", "start": "11:15", "end": "11:30", "type": "spiritual", "priority": 1},
      {"id": "lunch", "name": "Cơm trưa", "start": "11:30", "end": "12:00", "type": "meal", "priority": 1},
      {"id": "nap", "name": "Nghỉ trưa", "start": "12:00", "end": "13:45", "type": "rest", "priority": 1},
      {"id": "afternoon_wakeup", "name": "Thức dậy + vệ sinh", "start": "13:45", "end": "14:00", "type": "fixed", "priority": 1},
      {"id": "visit_christ", "name": "Viếng Chúa", "start": "14:00", "end": "14:30", "type": "spiritual", "priority": 1},
      {"id": "sports", "name": "Thể thao + vệ sinh cá nhân", "start": "16:30", "end": "18:00", "type": "health", "priority": 1},
      {"id": "dinner", "name": "Ăn tối", "start": "18:00", "end": "18:45", "type": "meal", "priority": 1},
      {"id": "transition_evening", "name": "Nghỉ / chuẩn bị giờ tối", "start": "18:45", "end": "19:15", "type": "transition", "priority": 1},
      {"id": "evening_prayer", "name": "Kinh tối", "start": "19:15", "end": "19:30", "type": "spiritual", "priority": 1},
      {"id": "daily_review", "name": "Tổng kết ngày / chuẩn bị ngày mai", "start": "21:10", "end": "21:20", "type": "planning", "priority": 1},
      {"id": "spiritual_journal", "name": "Nhật ký thiêng liêng", "start": "21:20", "end": "21:35", "duration_minutes": 15, "type": "spiritual", "priority": 1, "mandatory": true},
      {"id": "sleep_preparation", "name": "Chuẩn bị ngủ", "start": "21:35", "end": "21:45", "type": "rest", "priority": 1},
      {"id": "sleep", "name": "Ngủ", "start": "21:45", "end": "04:25", "type": "rest", "priority": 1, "mandatory": true}
    ],
    "official_class_schedule": [
      {"day": "monday", "time": "08:00-08:40", "period": 1, "subject": "Phụng vụ và Bí tích Tổng quát", "type": "class"},
      {"day": "monday", "time": "08:45-09:25", "period": 2, "subject": "PP. Suy niệm & Viết Suy niệm Lời Chúa", "teacher": "Cha Giuse Cung", "type": "class"},
      {"day": "monday", "time": "09:35-10:15", "period": 3, "subject": "Giáo lý HTCG 1", "teacher": "Cha Phêrô Việt", "type": "class"},
      {"day": "monday", "time": "10:20-11:00", "period": 4, "subject": "Giáo lý HTCG 1", "teacher": "Cha Phêrô Việt", "type": "class"},
      {"day": "monday", "time": "14:15-14:55", "period": 5, "subject": "Đọc sách chung", "week_pattern": "week_1_and_3", "type": "class"},
      {"day": "monday", "time": "14:15-14:55", "period": 5, "subject": "Lao động", "week_pattern": "week_2_and_4", "type": "class"},
      {"day": "tuesday", "time": "08:00-08:40", "period": 1, "subject": "Tiếng Việt thực hành 1 & Văn nghị luận 1", "teacher": "Thầy Quỳnh", "type": "class"},
      {"day": "tuesday", "time": "08:45-09:25", "period": 2, "subject": "Tiếng Việt thực hành 1 & Văn nghị luận 1", "teacher": "Thầy Quỳnh", "type": "class"},
      {"day": "tuesday", "time": "09:35-10:15", "period": 3, "subject": "Giáo lý HTCG 1", "teacher": "Cha Phêrô Việt", "type": "class"},
      {"day": "tuesday", "time": "10:20-11:00", "period": 4, "subject": "Giáo lý HTCG 1", "teacher": "Cha Phêrô Việt", "type": "class"},
      {"day": "tuesday", "time": "14:30-16:25", "subject": "Xướng âm, Nhạc lý căn bản & Thực hành đàn Organ 1", "teacher": "Cha GB. Tịnh", "type": "class"},
      {"day": "wednesday", "time": "08:00-11:00", "subject": "Các kỹ năng mềm + PP. Học và Đọc sách", "teacher": "Cha Phụ trách", "week_range": "week_1_to_mid_october", "type": "class"},
      {"day": "wednesday", "time": "08:00-11:00", "subject": "Language Skills 1A - Reading & Writing", "teacher": "Cô Kim Hương", "week_range": "from_mid_october", "type": "class"},
      {"day": "wednesday", "time": "14:30-16:25", "subject": "Grammar 1 & Basic Translation 1", "teacher": "Thầy Phaolô An", "week_range": "week_1_to_mid_october", "type": "class"},
      {"day": "wednesday", "time": "14:30-16:25", "subject": "Language Skills 1B - Listening & Speaking", "teacher": "Cô Kim Hương", "week_range": "from_mid_october", "type": "class"},
      {"day": "thursday", "time": "08:00-09:25", "subject": "Pronunciation", "teacher": "Sister Belen", "effective_from": "2026-09-24", "type": "class"},
      {"day": "thursday", "time": "09:35-11:00", "subject": "Language Skills 1B - Listening & Speaking", "teacher": "Sister Belen", "effective_from": "2026-09-24", "type": "class"},
      {"day": "thursday", "time": "14:30-16:25", "subject": "Grammar 1 & Basic Translation 1", "teacher": "Thầy Phaolô An", "effective_from": "2026-09-24", "type": "class"},
      {"day": "friday", "time": "08:00-11:00", "subject": "Phân định ơn gọi & Tổng quát Đấng, Linh đạo ĐSTF", "teacher": "Cha Phụ trách", "week_pattern": "week_1_and_3", "type": "class"},
      {"day": "friday", "time": "08:00-11:00", "subject": "Đọc sách", "week_pattern": "week_2_and_4", "type": "class"},
      {"day": "friday", "time": "14:30-16:25", "subject": "English Vocabulary in Use 1", "teacher": "Thầy Phêrô Điệp", "type": "class"},
      {"day": "friday", "time": "14:30-16:25", "subject": "Basic Translation 1", "type": "class"}
    ],
    "personal_study_subjects": [
      {"id": "english", "name": "Tiếng Anh", "category": "personal_study", "priority": 1, "target_ratio": 50, "weekly_target_minutes": 315, "monthly_target_minutes": null, "skills": ["Vocabulary", "Grammar", "Reading", "Listening", "Speaking", "Pronunciation", "Translation"]},
      {"id": "vietnamese_literature", "name": "Việt văn", "category": "personal_study", "priority": 2, "weekly_target_minutes": 105, "monthly_target_minutes": null},
      {"id": "instrument", "name": "Đàn / Organ", "category": "personal_study", "priority": 2, "weekly_target_minutes": 75, "monthly_target_minutes": null, "skills": ["Xướng âm", "Nhạc lý", "Kỹ thuật đàn", "Luyện bài"]},
      {"id": "reading", "name": "Đọc sách", "category": "personal_study", "priority": 3, "weekly_target_minutes": 135, "monthly_target_minutes": null}
    ],
    "other_study_activities": [
      {"id": "review_homework", "name": "Ôn bài / Làm bài tập", "category": "academic", "priority": 1, "weekly_target_minutes": 70},
      {"id": "spiritual_journal", "name": "Nhật ký thiêng liêng", "category": "spiritual", "priority": 1, "daily_minimum_minutes": 15, "weekly_target_minutes": 105}
    ],
    "weekly_personal_study_target": {"english": 315, "vietnamese_literature": 105, "instrument": 75, "reading": 135, "total_minutes": 630, "english_ratio": 50},
    "evening_study_slots": [
      {"slot": 1, "start": "19:30", "end": "20:15", "duration_minutes": 45},
      {"slot": 2, "start": "20:25", "end": "21:10", "duration_minutes": 45}
    ],
    "weekly_personal_study_plan": {
      "monday": [{"start": "19:30", "end": "20:15", "activity": "review_homework"}, {"start": "20:25", "end": "21:10", "activity": "english", "focus": "Vocabulary"}],
      "tuesday": [{"start": "19:30", "end": "20:15", "activity": "vietnamese_literature"}, {"start": "20:25", "end": "21:10", "activity": "instrument", "focus": "Đàn + Nhạc lý"}],
      "wednesday": [{"start": "19:30", "end": "20:15", "activity": "english", "focus": "Grammar"}, {"start": "20:25", "end": "21:10", "activity": "english", "focus": "Reading / Translation"}],
      "thursday": [{"start": "19:30", "end": "20:15", "activity": "english", "focus": "Listening + Pronunciation"}, {"start": "20:25", "end": "21:10", "activity": "english", "focus": "Grammar / Translation"}],
      "friday": [{"start": "19:30", "end": "20:15", "activity": "review_homework", "focus": "Tổng ôn tuần"}, {"start": "20:25", "end": "21:10", "activity": "english", "focus": "Vocabulary + Translation"}],
      "saturday": [{"start": "19:30", "end": "20:15", "activity": "vietnamese_literature"}, {"start": "20:25", "end": "21:10", "activity": "english", "focus": "Speaking"}],
      "sunday": [{"start": "19:30", "end": "20:15", "activity": "english", "focus": "Weekly Review"}, {"start": "20:25", "end": "21:10", "activity": "reading"}]
    },
    "priority_rules": [
      {"priority": 1, "items": ["fixed_schedule", "official_class", "mandatory_homework", "sleep", "spiritual_journal"]},
      {"priority": 2, "items": ["english", "vietnamese_literature", "instrument"]},
      {"priority": 3, "items": ["reading", "optional_personal_development"]}
    ],
    "planning_rules": {
      "do_not_overlap_fixed_schedule": true, "do_not_overlap_official_class": true,
      "latest_study_end_time": "21:10", "journal_required_every_day": true,
      "journal_minimum_minutes": 15, "sleep_time_fixed": "21:45",
      "english_ratio_target": 50, "english_ratio_tolerance": 0,
      "auto_reschedule_missed_sessions": true, "avoid_overloading_user": true,
      "carry_deficit_to_next_available_slot": true
    },
    "weekly_review": {
      "enabled": true, "day": "sunday",
      "metrics": ["total_study_minutes", "english_minutes", "english_ratio", "vietnamese_literature_minutes", "instrument_minutes", "reading_minutes", "homework_completion", "journal_completion", "plan_completion_rate"]
    },
    "monthly_review": {
      "enabled": true,
      "metrics": ["total_study_hours", "english_hours", "english_ratio", "vietnamese_literature_hours", "instrument_hours", "reading_hours", "homework_completion", "journal_completion", "study_streak", "monthly_goal_completion"]
    },
    "semester": {
      "academic_year": "2026-2027", "semester": 1, "name": "Học kỳ 1",
      "goal_tracking": true, "hierarchy": ["semester", "month", "week", "day", "study_session"]
    }
  }'::jsonb
), true
WHERE NOT EXISTS (SELECT 1 FROM sample_templates WHERE is_default = true);
