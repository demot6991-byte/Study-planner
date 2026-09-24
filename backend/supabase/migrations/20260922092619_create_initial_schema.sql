/*
# Seminarian Study Planner - Initial Schema

## Overview
Creates the full database schema for a personal study planning application
designed for a seminarian (chủng sinh/thỉnh sinh). This is a single-user app
with no authentication — all data belongs to one user and is accessible via
the anon key.

## New Tables

1. **settings** — user configuration (wake time, sleep time, English %, session duration, etc.)
2. **fixed_activities** — daily recurring blocked time slots (Thánh lễ, ăn, ngủ, etc.)
3. **schedule_entries** — formal class schedule by weekday (thời khóa biểu)
4. **study_subjects** — self-study subjects (English, Việt văn, Đàn, Đọc sách, etc.)
5. **tasks** — homework/assignments with priority and due dates
6. **study_sessions** — planned or completed study sessions
7. **journal_entries** — spiritual journal (nhật ký thiêng liêng)
8. **books** — book/reading tracker
9. **instrument_practices** — instrument practice tracker
10. **weekly_goals** — weekly goals per subject
11. **monthly_goals** — monthly goals per subject
12. **semester_goals** — semester-level goals
13. **daily_progress** — aggregated daily completion stats
14. **weekly_reviews** — weekly review reflections
15. **monthly_reviews** — monthly review reflections

## Security
- RLS enabled on all tables.
- All policies use `TO anon, authenticated` with `USING (true)` since this is
  a single-tenant app with no sign-in — data is intentionally shared/public.
*/

-- ============================================================
-- 1. SETTINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wake_time text NOT NULL DEFAULT '04:25',
  sleep_time text NOT NULL DEFAULT '21:45',
  mass_time_start text NOT NULL DEFAULT '04:45',
  mass_time_end text NOT NULL DEFAULT '06:00',
  breakfast_start text NOT NULL DEFAULT '06:00',
  breakfast_end text NOT NULL DEFAULT '08:00',
  lunch_start text NOT NULL DEFAULT '11:30',
  lunch_end text NOT NULL DEFAULT '12:00',
  nap_start text NOT NULL DEFAULT '12:00',
  nap_end text NOT NULL DEFAULT '13:45',
  sports_start text NOT NULL DEFAULT '16:30',
  sports_end text NOT NULL DEFAULT '18:00',
  dinner_start text NOT NULL DEFAULT '18:00',
  dinner_end text NOT NULL DEFAULT '18:45',
  evening_prayer_time text NOT NULL DEFAULT '19:15',
  study_block1_start text NOT NULL DEFAULT '08:00',
  study_block1_end text NOT NULL DEFAULT '11:00',
  study_block2_start text NOT NULL DEFAULT '14:30',
  study_block2_end text NOT NULL DEFAULT '16:25',
  self_study_start text NOT NULL DEFAULT '19:30',
  self_study_end text NOT NULL DEFAULT '21:20',
  session_duration_min int NOT NULL DEFAULT 45,
  break_duration_min int NOT NULL DEFAULT 10,
  english_target_pct int NOT NULL DEFAULT 50,
  journal_min_min int NOT NULL DEFAULT 15,
  notifications_enabled boolean NOT NULL DEFAULT true,
  notify_before_study_min int NOT NULL DEFAULT 10,
  notify_before_end_min int NOT NULL DEFAULT 5,
  notify_journal boolean NOT NULL DEFAULT true,
  notify_sleep boolean NOT NULL DEFAULT true,
  notify_incomplete boolean NOT NULL DEFAULT true,
  notify_weekly_review boolean NOT NULL DEFAULT true,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_settings" ON settings;
CREATE POLICY "anon_all_settings" ON settings FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 2. FIXED_ACTIVITIES — daily recurring blocked time
-- ============================================================
CREATE TABLE IF NOT EXISTS fixed_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  category text NOT NULL DEFAULT 'fixed',
  icon text,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE fixed_activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_fixed_activities" ON fixed_activities;
CREATE POLICY "anon_all_fixed_activities" ON fixed_activities FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 3. SCHEDULE_ENTRIES — formal class schedule
-- ============================================================
CREATE TABLE IF NOT EXISTS schedule_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  weekday int NOT NULL CHECK (weekday >= 0 AND weekday <= 6),
  -- 0=Sun, 1=Mon, ... 6=Sat
  start_time text NOT NULL,
  end_time text NOT NULL,
  subject_name text NOT NULL,
  session_type text NOT NULL DEFAULT 'class',
  -- 'class' | 'study' | 'reading' | 'labor'
  note text,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE schedule_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_schedule_entries" ON schedule_entries;
CREATE POLICY "anon_all_schedule_entries" ON schedule_entries FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 4. STUDY_SUBJECTS — self-study subjects
-- ============================================================
CREATE TABLE IF NOT EXISTS study_subjects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text NOT NULL UNIQUE,
  -- 'english', 'vietnamese', 'instrument', 'reading', 'homework', 'journal'
  color text NOT NULL DEFAULT '#3b82f6',
  icon text,
  is_in_english_ratio boolean NOT NULL DEFAULT false,
  -- true for english, vietnamese, instrument, reading
  weekly_goal_min int NOT NULL DEFAULT 0,
  monthly_goal_min int NOT NULL DEFAULT 0,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE study_subjects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_study_subjects" ON study_subjects;
CREATE POLICY "anon_all_study_subjects" ON study_subjects FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 5. TASKS — homework / assignments
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  subject_code text,
  priority int NOT NULL DEFAULT 2,
  -- 1=highest (homework), 2=medium (english/vietnamese/instrument), 3=low (reading)
  due_date date,
  estimated_min int NOT NULL DEFAULT 30,
  actual_min int,
  status text NOT NULL DEFAULT 'pending',
  -- 'pending', 'in_progress', 'completed', 'skipped'
  note text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_tasks" ON tasks;
CREATE POLICY "anon_all_tasks" ON tasks FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 6. STUDY_SESSIONS — planned or completed sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  subject_code text NOT NULL,
  skill text,
  -- for english: vocabulary, grammar, reading, listening, speaking, pronunciation, translation
  title text NOT NULL,
  planned_min int NOT NULL,
  actual_min int,
  status text NOT NULL DEFAULT 'planned',
  -- 'planned', 'completed', 'skipped', 'rescheduled'
  priority int NOT NULL DEFAULT 2,
  note text,
  source text NOT NULL DEFAULT 'auto',
  -- 'auto' (generated by planner) or 'manual'
  rescheduled_from uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_study_sessions" ON study_sessions;
CREATE POLICY "anon_all_study_sessions" ON study_sessions FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_study_sessions_date ON study_sessions(date);

-- ============================================================
-- 7. JOURNAL_ENTRIES — spiritual journal
-- ============================================================
CREATE TABLE IF NOT EXISTS journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_date date NOT NULL UNIQUE,
  grateful_for text,
  good_deed text,
  needs_improvement text,
  realization text,
  want_to_change text,
  prayer text,
  duration_min int NOT NULL DEFAULT 15,
  completed boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_journal_entries" ON journal_entries;
CREATE POLICY "anon_all_journal_entries" ON journal_entries FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_journal_entries_date ON journal_entries(entry_date);

-- ============================================================
-- 8. BOOKS — reading tracker
-- ============================================================
CREATE TABLE IF NOT EXISTS books (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  author text,
  total_pages int NOT NULL DEFAULT 0,
  current_page int NOT NULL DEFAULT 0,
  daily_goal_pages int NOT NULL DEFAULT 10,
  start_date date,
  target_date date,
  note text,
  status text NOT NULL DEFAULT 'reading',
  -- 'reading', 'completed', 'paused'
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE books ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_books" ON books;
CREATE POLICY "anon_all_books" ON books FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 9. INSTRUMENT_PRACTICES — instrument practice tracker
-- ============================================================
CREATE TABLE IF NOT EXISTS instrument_practices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  practice_date date NOT NULL,
  solfege_min int NOT NULL DEFAULT 0,
  theory_min int NOT NULL DEFAULT 0,
  technique_min int NOT NULL DEFAULT 0,
  repertoire text,
  practice_min int NOT NULL DEFAULT 0,
  note text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE instrument_practices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_instrument_practices" ON instrument_practices;
CREATE POLICY "anon_all_instrument_practices" ON instrument_practices FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_instrument_practices_date ON instrument_practices(practice_date);

-- ============================================================
-- 10. WEEKLY_GOALS — goals per subject per week
-- ============================================================
CREATE TABLE IF NOT EXISTS weekly_goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL,
  -- Monday of the week
  subject_code text NOT NULL,
  target_min int NOT NULL DEFAULT 0,
  actual_min int NOT NULL DEFAULT 0,
  skill text,
  -- null for overall, or specific english skill
  note text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (week_start, subject_code, skill)
);

ALTER TABLE weekly_goals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_weekly_goals" ON weekly_goals;
CREATE POLICY "anon_all_weekly_goals" ON weekly_goals FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_weekly_goals_week ON weekly_goals(week_start);

-- ============================================================
-- 11. MONTHLY_GOALS — goals per subject per month
-- ============================================================
CREATE TABLE IF NOT EXISTS monthly_goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year int NOT NULL,
  month int NOT NULL CHECK (month >= 1 AND month <= 12),
  subject_code text NOT NULL,
  target_min int NOT NULL DEFAULT 0,
  actual_min int NOT NULL DEFAULT 0,
  target_tasks int NOT NULL DEFAULT 0,
  completed_tasks int NOT NULL DEFAULT 0,
  target_journal_days int NOT NULL DEFAULT 0,
  actual_journal_days int NOT NULL DEFAULT 0,
  note text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (year, month, subject_code)
);

ALTER TABLE monthly_goals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_monthly_goals" ON monthly_goals;
CREATE POLICY "anon_all_monthly_goals" ON monthly_goals FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 12. SEMESTER_GOALS
-- ============================================================
CREATE TABLE IF NOT EXISTS semester_goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  english_target_min int NOT NULL DEFAULT 0,
  vietnamese_target_min int NOT NULL DEFAULT 0,
  instrument_target_min int NOT NULL DEFAULT 0,
  reading_target_min int NOT NULL DEFAULT 0,
  target_books int NOT NULL DEFAULT 0,
  target_essays int NOT NULL DEFAULT 0,
  target_tasks int NOT NULL DEFAULT 0,
  target_journal_days int NOT NULL DEFAULT 0,
  note text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE semester_goals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_semester_goals" ON semester_goals;
CREATE POLICY "anon_all_semester_goals" ON semester_goals FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 13. DAILY_PROGRESS — aggregated daily stats
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  progress_date date NOT NULL UNIQUE,
  english_min int NOT NULL DEFAULT 0,
  vietnamese_min int NOT NULL DEFAULT 0,
  instrument_min int NOT NULL DEFAULT 0,
  reading_min int NOT NULL DEFAULT 0,
  homework_min int NOT NULL DEFAULT 0,
  journal_min int NOT NULL DEFAULT 0,
  total_study_min int NOT NULL DEFAULT 0,
  tasks_completed int NOT NULL DEFAULT 0,
  tasks_total int NOT NULL DEFAULT 0,
  journal_completed boolean NOT NULL DEFAULT false,
  plan_completed boolean NOT NULL DEFAULT false,
  english_ratio numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_daily_progress" ON daily_progress;
CREATE POLICY "anon_all_daily_progress" ON daily_progress FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_daily_progress_date ON daily_progress(progress_date);

-- ============================================================
-- 14. WEEKLY_REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS weekly_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL UNIQUE,
  total_study_min int NOT NULL DEFAULT 0,
  english_min int NOT NULL DEFAULT 0,
  vietnamese_min int NOT NULL DEFAULT 0,
  instrument_min int NOT NULL DEFAULT 0,
  reading_min int NOT NULL DEFAULT 0,
  english_ratio numeric NOT NULL DEFAULT 0,
  tasks_completed int NOT NULL DEFAULT 0,
  tasks_total int NOT NULL DEFAULT 0,
  journal_days int NOT NULL DEFAULT 0,
  completion_rate numeric NOT NULL DEFAULT 0,
  what_went_well text,
  what_needs_improvement text,
  next_week_focus text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE weekly_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_weekly_reviews" ON weekly_reviews;
CREATE POLICY "anon_all_weekly_reviews" ON weekly_reviews FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 15. MONTHLY_REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS monthly_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year int NOT NULL,
  month int NOT NULL,
  UNIQUE (year, month),
  total_study_min int NOT NULL DEFAULT 0,
  english_min int NOT NULL DEFAULT 0,
  vietnamese_min int NOT NULL DEFAULT 0,
  instrument_min int NOT NULL DEFAULT 0,
  reading_min int NOT NULL DEFAULT 0,
  english_ratio numeric NOT NULL DEFAULT 0,
  tasks_completed int NOT NULL DEFAULT 0,
  journal_days int NOT NULL DEFAULT 0,
  plan_completed_days int NOT NULL DEFAULT 0,
  streak int NOT NULL DEFAULT 0,
  reflection text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE monthly_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_monthly_reviews" ON monthly_reviews;
CREATE POLICY "anon_all_monthly_reviews" ON monthly_reviews FOR ALL
  TO anon, authenticated USING (true) WITH CHECK (true);
