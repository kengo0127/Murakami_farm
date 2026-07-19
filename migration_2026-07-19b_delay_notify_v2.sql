-- ============================================================
-- 村上農園 タスク管理アプリ 遅延通知メール v2 マイグレーション（2026-07-19）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   これまで task_delay_notifications は「1タスクにつき1回だけ通知」
--   （task_id を主キー）という設計だったが、以下の要件を追加するため
--   「1タスク×1種類の通知につき1回」に変更する。
--     1. 完了予定時刻から5分後の遅延通知（既存）
--     2. 休憩直前（9:55/11:55/14:55/16:55）の再チェック通知（新規）
--        → 休憩時間に管理者が対面で完了ボタンを確認・注意できるようにするため
--     3. 開始予定時刻から10分後、まだ開始されていない場合の通知（新規）
--
-- 注意：check-delayed-tasks Edge Function を先に更新・デプロイしてから
--       実行してください（cronスケジュール自体は変更しないため
--       cron.schedule の再登録は不要）。
-- ============================================================

alter table public.task_delay_notifications
  add column if not exists notification_type text not null default 'completion_delay';

alter table public.task_delay_notifications
  drop constraint if exists task_delay_notifications_pkey;

alter table public.task_delay_notifications
  add primary key (task_id, notification_type);

-- ============================================================
-- 完了！
-- ============================================================
