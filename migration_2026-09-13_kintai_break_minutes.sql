-- ============================================================
-- 勤怠打刻に「休憩時間」を記録できるようにする
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

alter table public.attendance_records
  add column break_minutes integer;

alter table public.attendance_records
  add constraint attendance_records_break_minutes_check
  check (break_minutes is null or break_minutes in (15, 60, 75, 90, 120));

-- ============================================================
-- 完了！
-- ============================================================
