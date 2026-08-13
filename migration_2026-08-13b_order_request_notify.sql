-- ============================================================
-- 村上農園 インスタ・EC注文リクエスト通知（LINE） マイグレーション（2026-08-13）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. melon_order_requests に通知送信済みフラグを追加
--      （同じリクエストに何度も通知しないようにするための記録）
--   2. 5分間隔で notify-order-requests Edge Function を自動実行する
--      cronジョブの登録
--
-- 注意：Edge Function（notify-order-requests）を先にデプロイしてから
--       このSQLを実行してください。
--       通知先は、タスクの遅延通知（check-delayed-tasks）と同じ
--       line_recipients テーブル（label = 'admin_alert'）を共用します。
--       すでにLINE公式アカウントの友だち追加が完了していれば、
--       追加の登録作業は不要です。
-- ============================================================

alter table public.melon_order_requests
  add column if not exists notified_new_at     timestamptz,
  add column if not exists notified_overdue_at timestamptz;

select cron.schedule(
  'notify-order-requests',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://wquwvkjnngqkiepthstq.supabase.co/functions/v1/notify-order-requests',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 既に同名ジョブが存在する場合、上記でエラーになったら先にこちらを実行してから再登録
-- select cron.unschedule('notify-order-requests');

-- ============================================================
-- 完了！
-- ============================================================
