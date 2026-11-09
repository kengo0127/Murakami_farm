-- ============================================================
-- 作業日報の「場所」を管理者が編集できるようにする（2026-11-09）
-- migration_2026-11-09_nippo_options.sql の後に実行してください
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   スタッフの「作業を追加」で選ぶ場所（ハウス／露地／その他 など）をテーブルで管理する。
--   管理画面「作業日報 → 日報を編集する」から追加・削除・並べ替えができる。
--   needs_number = true の場所は、スタッフが番号を必ず書く（ハウス3、露地12 など）。
--   場所の種類を自由に増やせるよう、daily_work_entries.location_type の固定チェック（ハウス／露地のみ）を外す。
-- ============================================================

alter table public.daily_work_entries
  drop constraint if exists daily_work_entries_location_type_check;

create table public.nippo_places (
  id            uuid primary key default gen_random_uuid(),
  name          text not null unique,
  icon          text not null default '📍',
  needs_number  boolean not null default true,
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now()
);

alter table public.nippo_places enable row level security;

create policy "ログイン済みユーザーは日報の場所を閲覧できる"
  on public.nippo_places for select
  using (auth.role() = 'authenticated');

create policy "管理者は日報の場所を編集できる"
  on public.nippo_places for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

insert into public.nippo_places (name, icon, needs_number, sort_order) values
  ('ハウス', '🏠', true,  1),
  ('露地',   '🌾', true,  2),
  ('その他', '📍', false, 3);

-- ============================================================
-- 完了！
-- ============================================================
