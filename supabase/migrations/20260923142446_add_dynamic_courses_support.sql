/*
# Add Dynamic Courses Support

## Overview
Transitions the subject/course system from static/hardcoded to dynamic/user-defined.
Users can now create custom courses with descriptions, tags, accent colors, icons,
and control whether each course appears in the navigation sidebar.

## Changes

### 1. study_subjects — new columns
- `description` (text, nullable) — user-defined course description
- `tags` (text[], nullable) — array of user-defined tags for categorization
- `show_in_nav` (boolean, default true) — whether this course appears in the sidebar
- `icon_name` (text, nullable) — Lucide icon name for sidebar/menu rendering

### 2. schedule_entries — new columns
- `subject_id` (uuid, nullable, FK → study_subjects.id) — link schedule entry to a course
- `recurrence` (text, default 'weekly') — recurrence pattern: 'weekly', 'daily', 'once', 'biweekly'
- `recurrence_end_date` (date, nullable) — when recurrence ends (null = no end)

### 3. study_subjects — relax unique constraint
The existing unique constraint `study_subjects_user_id_code_key` on (user_id, code)
remains, but `code` is now user-defined (not from a fixed list). The `code` column
is made nullable to support user-created courses without a code.

## Security
- RLS already enabled on both tables (multi-user, owner-scoped via auth.uid() = user_id)
- No policy changes needed — existing 4-policy CRUD per table covers new columns
- New columns inherit the same ownership rules

## Notes
- Existing data is preserved: all current subjects get show_in_nav=true, icon_name from their code
- schedule_entries.subject_id is nullable for backward compatibility with existing entries
  that use subject_name (free text) instead of a course reference
*/

-- 1. Add new columns to study_subjects
ALTER TABLE study_subjects
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS show_in_nav boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS icon_name text;

-- Make code nullable (user-created courses may not have a code)
ALTER TABLE study_subjects ALTER COLUMN code DROP NOT NULL;

-- 2. Add new columns to schedule_entries
ALTER TABLE schedule_entries
  ADD COLUMN IF NOT EXISTS subject_id uuid REFERENCES study_subjects(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS recurrence text NOT NULL DEFAULT 'weekly',
  ADD COLUMN IF NOT EXISTS recurrence_end_date date;

-- 3. Backfill icon_name for existing subjects based on their code
UPDATE study_subjects SET icon_name = CASE
  WHEN code = 'english' THEN 'Languages'
  WHEN code = 'vietnamese' THEN 'PenLine'
  WHEN code = 'instrument' THEN 'Music'
  WHEN code = 'reading' THEN 'BookMarked'
  WHEN code = 'homework' THEN 'GraduationCap'
  WHEN code = 'journal' THEN 'Heart'
  ELSE 'BookOpen'
END
WHERE icon_name IS NULL;

-- 4. Add index on subject_id for schedule_entries lookups
CREATE INDEX IF NOT EXISTS idx_schedule_entries_subject_id ON schedule_entries(subject_id);

-- 5. Add index on show_in_nav for sidebar rendering
CREATE INDEX IF NOT EXISTS idx_study_subjects_show_in_nav ON study_subjects(show_in_nav);
