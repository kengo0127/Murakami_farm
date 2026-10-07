-- ============================================================
-- 勤怠打刻の休憩時間を「直接入力」できるようにする（2026-10-07）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   これまで休憩時間は 15/60/75/90/120分 のいずれかしか保存できない
--   制約になっていたため、0〜600分の任意の分数を保存できるように変更する。
--   （画面側の選択肢は従来どおり残し、「直接入力」を追加）
-- ============================================================

alter table public.attendance_records
  drop constraint if exists attendance_records_break_minutes_check;

alter table public.attendance_records
  add constraint attendance_records_break_minutes_check
  check (break_minutes is null or break_minutes between 0 and 600);

-- ============================================================
-- 完了！
-- ============================================================
