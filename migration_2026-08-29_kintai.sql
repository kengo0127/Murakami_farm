-- ============================================================
-- 勤怠管理（出勤・退勤の打刻）機能を追加する
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

-- profiles.role に 'kiosk'（事務所タブレット用の共有ログインアカウント）を追加
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('staff', 'admin', 'kiosk'));

-- ============================================================
-- attendance_records（出勤・退勤記録）
-- 1スタッフ・1日につき1レコード
-- ============================================================
create table public.attendance_records (
  id         uuid primary key default gen_random_uuid(),
  staff_id   uuid not null references public.profiles(id) on delete cascade,
  date       date not null,
  clock_in   timestamptz,
  clock_out  timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(staff_id, date)
);

alter table public.attendance_records enable row level security;

create policy "ログイン済みユーザーは勤怠記録を閲覧できる"
  on public.attendance_records for select
  using (auth.role() = 'authenticated');

create policy "ログイン済みユーザーは勤怠を記録できる"
  on public.attendance_records for insert
  with check (auth.role() = 'authenticated');

create policy "ログイン済みユーザーは勤怠記録を更新できる"
  on public.attendance_records for update
  using (auth.role() = 'authenticated');

create policy "ログイン済みユーザーは勤怠記録を削除できる（打刻の取消用）"
  on public.attendance_records for delete
  using (auth.role() = 'authenticated');

-- ============================================================
-- 完了！
-- 続けて、事務所タブレット用の共有ログインアカウントを
-- Supabaseダッシュボード（Authentication → Users）から作成し、
-- そのユーザーの profiles.role を 'kiosk' に変更してください。
-- 例：
--   update public.profiles set role = 'kiosk' where id = '（作成したユーザーのUUID）';
-- ============================================================
