-- ============================================================
-- 勤怠データの日次Excelレポート マイグレーション（2026-09-21）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   毎日20:00 JST（= 11:00 UTC）に daily-attendance-report Edge Function
--   を自動実行するcronジョブを登録する。
--   その日の勤怠データ（attendance_records）を、admin.htmlの
--   「Excelダウンロード」機能と同じ形式（日別勤怠記録＋スタッフ別集計）で
--   Excel（.xlsx）にまとめ、Resend経由でメール添付送信する。
--
-- 事前準備（このSQLを実行する前に）：
--   1. daily-attendance-report Edge Function をデプロイしておくこと
--      （Supabaseダッシュボード → Edge Functions → 新しい関数を作成 →
--       supabase/functions/daily-attendance-report/index.ts の内容を貼り付け）
--   2. RESEND_API_KEY と ATTENDANCE_BACKUP_EMAIL が既にSupabase
--      Edge Functions > Secrets に登録済みであること
--      （毎週日曜の勤怠バックアップ機能：migration_2026-08-30b_attendance_backup.sql
--       と同じ2つのSecretsを共用する。未登録の場合は、そちらの事前準備
--       （村上様にResendアカウントを作成していただく）を先に完了させてください）
-- ============================================================

select cron.schedule(
  'daily-attendance-report',
  '0 11 * * *',
  $$
  select net.http_post(
    url := 'https://wquwvkjnngqkiepthstq.supabase.co/functions/v1/daily-attendance-report',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 既に同名ジョブが存在する場合、上記でエラーになったら先にこちらを実行してから再登録
-- select cron.unschedule('daily-attendance-report');

-- ============================================================
-- 完了！
-- ============================================================
