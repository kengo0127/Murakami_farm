-- ============================================================
-- 村上農園 タスク管理アプリ 遅延通知メール マイグレーション
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. task_delay_notifications（遅延通知の送信済み記録）テーブルの作成
--      → 同じタスクに何度もメールを送らないようにするための記録テーブル
--      → Edge Function（サービスロール）からのみ読み書きする想定のため、
--        クライアント向けのRLSポリシーは追加しない（RLS有効・ポリシーなし＝全拒否）
--   2. pg_cron / pg_net 拡張機能の有効化
--   3. 5分間隔でEdge Functionを自動実行するcronジョブの登録
--
-- 注意：Edge Function（check-delayed-tasks）を先にデプロイしてから
--       このSQLの「3. cronジョブの登録」部分を実行してください。
-- ============================================================


-- ============================================================
-- 1. task_delay_notifications（遅延通知の送信済み記録）
-- ============================================================
create table if not exists public.task_delay_notifications (
  task_id     uuid primary key references public.tasks(id) on delete cascade,
  notified_at timestamptz not null default now()
);

alter table public.task_delay_notifications enable row level security;
-- ポリシーを追加しない = anon/authenticatedからは読み書き不可（service_roleのみアクセス可）


-- ============================================================
-- 2. 拡張機能の有効化
-- ============================================================
create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;


-- ============================================================
-- 3. cronジョブの登録（Edge Functionデプロイ後に実行）
-- 5分ごとにcheck-delayed-tasks関数を呼び出す
-- ============================================================
select cron.schedule(
  'check-delayed-tasks',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://wquwvkjnngqkiepthstq.supabase.co/functions/v1/check-delayed-tasks',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 既に同名ジョブが存在する場合、上記でエラーになったら先にこちらを実行してから再登録
-- select cron.unschedule('check-delayed-tasks');


-- ============================================================
-- 完了！
-- ============================================================
