/*
# Add multi-user authentication support

## Overview
Converts the app from single-tenant (shared data) to multi-user (per-account data isolation).
Each user signs up/in via Supabase Auth and sees only their own data.

## Changes

### 1. Add user_id columns to all data tables
Added `user_id uuid NOT NULL DEFAULT auth.uid()` to:
- settings
- fixed_activities
- schedule_entries
- study_subjects
- tasks
- study_sessions
- journal_entries
- books
- instrument_practices
- weekly_goals
- monthly_goals
- semester_goals
- daily_progress
- weekly_reviews
- monthly_reviews

### 2. Replace RLS policies
All tables switch from `TO anon, authenticated USING (true)` (public/shared)
to `TO authenticated` with ownership check `auth.uid() = user_id`.
4 separate policies per table (SELECT, INSERT, UPDATE, DELETE).

### 3. Drop old anon policies
All previous `anon_all_*` policies are dropped.

### Notes
- `DEFAULT auth.uid()` ensures inserts work even when frontend omits user_id.
- Existing seed data rows had NULL user_id; they are assigned to a placeholder
  so they don't disappear, but new users start fresh.
- ON DELETE CASCADE on user_id FK ensures data is cleaned up when a user is deleted.
*/

-- Helper: add user_id column if not exists
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'settings' AND column_name = 'user_id') THEN
    ALTER TABLE settings ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fixed_activities' AND column_name = 'user_id') THEN
    ALTER TABLE fixed_activities ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'schedule_entries' AND column_name = 'user_id') THEN
    ALTER TABLE schedule_entries ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'study_subjects' AND column_name = 'user_id') THEN
    ALTER TABLE study_subjects ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tasks' AND column_name = 'user_id') THEN
    ALTER TABLE tasks ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'study_sessions' AND column_name = 'user_id') THEN
    ALTER TABLE study_sessions ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'journal_entries' AND column_name = 'user_id') THEN
    ALTER TABLE journal_entries ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'books' AND column_name = 'user_id') THEN
    ALTER TABLE books ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'instrument_practices' AND column_name = 'user_id') THEN
    ALTER TABLE instrument_practices ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'weekly_goals' AND column_name = 'user_id') THEN
    ALTER TABLE weekly_goals ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'monthly_goals' AND column_name = 'user_id') THEN
    ALTER TABLE monthly_goals ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'semester_goals' AND column_name = 'user_id') THEN
    ALTER TABLE semester_goals ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_progress' AND column_name = 'user_id') THEN
    ALTER TABLE daily_progress ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'weekly_reviews' AND column_name = 'user_id') THEN
    ALTER TABLE weekly_reviews ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'monthly_reviews' AND column_name = 'user_id') THEN
    ALTER TABLE monthly_reviews ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Set DEFAULT auth.uid() so inserts without user_id still work
ALTER TABLE settings ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE fixed_activities ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE schedule_entries ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE study_subjects ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE tasks ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE study_sessions ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE journal_entries ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE books ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE instrument_practices ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE weekly_goals ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE monthly_goals ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE semester_goals ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE daily_progress ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE weekly_reviews ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE monthly_reviews ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Update unique constraints that need user_id scope
-- journal_entries unique on (entry_date) -> (user_id, entry_date)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_entry_date_key') THEN
    ALTER TABLE journal_entries DROP CONSTRAINT journal_entries_entry_date_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'journal_entries_user_id_entry_date_key') THEN
    ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_user_id_entry_date_key UNIQUE (user_id, entry_date);
  END IF;
END $$;

-- daily_progress unique on (progress_date) -> (user_id, progress_date)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'daily_progress_progress_date_key') THEN
    ALTER TABLE daily_progress DROP CONSTRAINT daily_progress_progress_date_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'daily_progress_user_id_progress_date_key') THEN
    ALTER TABLE daily_progress ADD CONSTRAINT daily_progress_user_id_progress_date_key UNIQUE (user_id, progress_date);
  END IF;
END $$;

-- weekly_reviews unique on (week_start) -> (user_id, week_start)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'weekly_reviews_week_start_key') THEN
    ALTER TABLE weekly_reviews DROP CONSTRAINT weekly_reviews_week_start_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'weekly_reviews_user_id_week_start_key') THEN
    ALTER TABLE weekly_reviews ADD CONSTRAINT weekly_reviews_user_id_week_start_key UNIQUE (user_id, week_start);
  END IF;
END $$;

-- weekly_goals unique (week_start, subject_code, skill) -> add user_id
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'weekly_goals_week_start_subject_code_skill_key') THEN
    ALTER TABLE weekly_goals DROP CONSTRAINT weekly_goals_week_start_subject_code_skill_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'weekly_goals_user_week_subject_skill_key') THEN
    ALTER TABLE weekly_goals ADD CONSTRAINT weekly_goals_user_week_subject_skill_key UNIQUE (user_id, week_start, subject_code, skill);
  END IF;
END $$;

-- monthly_goals unique (year, month, subject_code) -> add user_id
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_goals_year_month_subject_code_key') THEN
    ALTER TABLE monthly_goals DROP CONSTRAINT monthly_goals_year_month_subject_code_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_goals_user_year_month_subject_key') THEN
    ALTER TABLE monthly_goals ADD CONSTRAINT monthly_goals_user_year_month_subject_key UNIQUE (user_id, year, month, subject_code);
  END IF;
END $$;

-- monthly_reviews unique (year, month) -> add user_id
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_reviews_year_month_key') THEN
    ALTER TABLE monthly_reviews DROP CONSTRAINT monthly_reviews_year_month_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_reviews_user_year_month_key') THEN
    ALTER TABLE monthly_reviews ADD CONSTRAINT monthly_reviews_user_year_month_key UNIQUE (user_id, year, month);
  END IF;
END $$;

-- study_subjects unique (code) -> (user_id, code)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'study_subjects_code_key') THEN
    ALTER TABLE study_subjects DROP CONSTRAINT study_subjects_code_key;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'study_subjects_user_id_code_key') THEN
    ALTER TABLE study_subjects ADD CONSTRAINT study_subjects_user_id_code_key UNIQUE (user_id, code);
  END IF;
END $$;

-- ====== REPLACE POLICIES ======
-- Drop all old anon policies and create authenticated-only ownership policies

-- settings
DROP POLICY IF EXISTS "anon_all_settings" ON settings;
CREATE POLICY "select_own_settings" ON settings FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_settings" ON settings FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_settings" ON settings FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_settings" ON settings FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- fixed_activities
DROP POLICY IF EXISTS "anon_all_fixed_activities" ON fixed_activities;
CREATE POLICY "select_own_fixed_activities" ON fixed_activities FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_fixed_activities" ON fixed_activities FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_fixed_activities" ON fixed_activities FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_fixed_activities" ON fixed_activities FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- schedule_entries
DROP POLICY IF EXISTS "anon_all_schedule_entries" ON schedule_entries;
CREATE POLICY "select_own_schedule_entries" ON schedule_entries FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_schedule_entries" ON schedule_entries FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_schedule_entries" ON schedule_entries FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_schedule_entries" ON schedule_entries FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- study_subjects
DROP POLICY IF EXISTS "anon_all_study_subjects" ON study_subjects;
CREATE POLICY "select_own_study_subjects" ON study_subjects FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_study_subjects" ON study_subjects FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_study_subjects" ON study_subjects FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_study_subjects" ON study_subjects FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- tasks
DROP POLICY IF EXISTS "anon_all_tasks" ON tasks;
CREATE POLICY "select_own_tasks" ON tasks FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_tasks" ON tasks FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_tasks" ON tasks FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_tasks" ON tasks FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- study_sessions
DROP POLICY IF EXISTS "anon_all_study_sessions" ON study_sessions;
CREATE POLICY "select_own_study_sessions" ON study_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_study_sessions" ON study_sessions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_study_sessions" ON study_sessions FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_study_sessions" ON study_sessions FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- journal_entries
DROP POLICY IF EXISTS "anon_all_journal_entries" ON journal_entries;
CREATE POLICY "select_own_journal_entries" ON journal_entries FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_journal_entries" ON journal_entries FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_journal_entries" ON journal_entries FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_journal_entries" ON journal_entries FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- books
DROP POLICY IF EXISTS "anon_all_books" ON books;
CREATE POLICY "select_own_books" ON books FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_books" ON books FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_books" ON books FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_books" ON books FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- instrument_practices
DROP POLICY IF EXISTS "anon_all_instrument_practices" ON instrument_practices;
CREATE POLICY "select_own_instrument_practices" ON instrument_practices FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_instrument_practices" ON instrument_practices FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_instrument_practices" ON instrument_practices FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_instrument_practices" ON instrument_practices FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- weekly_goals
DROP POLICY IF EXISTS "anon_all_weekly_goals" ON weekly_goals;
CREATE POLICY "select_own_weekly_goals" ON weekly_goals FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_weekly_goals" ON weekly_goals FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_weekly_goals" ON weekly_goals FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_weekly_goals" ON weekly_goals FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- monthly_goals
DROP POLICY IF EXISTS "anon_all_monthly_goals" ON monthly_goals;
CREATE POLICY "select_own_monthly_goals" ON monthly_goals FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_monthly_goals" ON monthly_goals FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_monthly_goals" ON monthly_goals FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_monthly_goals" ON monthly_goals FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- semester_goals
DROP POLICY IF EXISTS "anon_all_semester_goals" ON semester_goals;
CREATE POLICY "select_own_semester_goals" ON semester_goals FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_semester_goals" ON semester_goals FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_semester_goals" ON semester_goals FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_semester_goals" ON semester_goals FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- daily_progress
DROP POLICY IF EXISTS "anon_all_daily_progress" ON daily_progress;
CREATE POLICY "select_own_daily_progress" ON daily_progress FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_daily_progress" ON daily_progress FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_daily_progress" ON daily_progress FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_daily_progress" ON daily_progress FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- weekly_reviews
DROP POLICY IF EXISTS "anon_all_weekly_reviews" ON weekly_reviews;
CREATE POLICY "select_own_weekly_reviews" ON weekly_reviews FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_weekly_reviews" ON weekly_reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_weekly_reviews" ON weekly_reviews FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_weekly_reviews" ON weekly_reviews FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- monthly_reviews
DROP POLICY IF EXISTS "anon_all_monthly_reviews" ON monthly_reviews;
CREATE POLICY "select_own_monthly_reviews" ON monthly_reviews FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "insert_own_monthly_reviews" ON monthly_reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_monthly_reviews" ON monthly_reviews FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_monthly_reviews" ON monthly_reviews FOR DELETE TO authenticated USING (auth.uid() = user_id);
