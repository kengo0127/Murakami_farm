-- ============================================================
-- データベース容量の確認用関数 マイグレーション（2026-11-08）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   無料プランのデータベースは500MBまで。超えるとアプリが使えなく
--   なるおそれがあるため、PCのバックアップスクリプト
--   （バックアップスクリプト\backup_murakami.ps1）が毎回この関数で
--   現在の容量を取得し、一定以上になったらWindowsの通知で知らせる。
--   管理者アカウントでログインしているときだけ値を返す。
-- ============================================================

create or replace function public.admin_db_size()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    raise exception '管理者のみ実行できます';
  end if;
  return pg_database_size(current_database());
end;
$$;

revoke all on function public.admin_db_size() from public, anon;
grant execute on function public.admin_db_size() to authenticated;

-- 確認用（SQL Editorでは管理者としてログインしていないためエラーになるのが正常）：
-- select pg_size_pretty(pg_database_size(current_database()));

-- ============================================================
-- 完了！
-- ============================================================
