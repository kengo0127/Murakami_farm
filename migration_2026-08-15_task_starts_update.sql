-- ============================================================
-- 村上農園 タスク管理アプリ 追加機能マイグレーション（2026-08-15）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   開始ボタンの押し忘れ等で記録された開始時刻を、
--   本人が後から修正できるようにするUPDATEポリシーを追加
-- ============================================================

drop policy if exists "本人は自分の開始記録の時刻を修正できる" on public.task_starts;
create policy "本人は自分の開始記録の時刻を修正できる"
  on public.task_starts for update
  using (auth.uid() = started_by)
  with check (auth.uid() = started_by);
