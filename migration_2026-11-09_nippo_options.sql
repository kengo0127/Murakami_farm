-- ============================================================
-- 作業日報の追加機能（2026-11-09）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. 選択肢（作物・作業）を管理者が編集できるようにする
--   スタッフ画面「今日の作業報告（日報）」の「作業を追加」で出てくる
--   作物ボタンと、作物ごとの作業ボタンをテーブルで管理する。
--   管理画面「作業日報 → 日報を編集する」（nippo_options.html）から追加・削除・並べ替えができる。
--   これまでスタッフ画面に直接書いていた仮のリストを初期データとして入れる。
--   ※選択肢を削除しても、登録済みの日報（daily_work_entries は作物名・作業名を文字で保存）は消えない
--   2. 日報に「作業した場所」（ハウス／露地 ＋ 番号）を追加
--   3. 管理画面の「今日の日報 入力状況」をリアルタイムで更新するため、日報と出退勤をRealtimeの対象にする
-- ============================================================

create table public.nippo_crops (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  icon        text not null default '📦',
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

create table public.nippo_tasks (
  id          uuid primary key default gen_random_uuid(),
  crop_id     uuid not null references public.nippo_crops(id) on delete cascade,
  name        text not null,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  unique (crop_id, name)
);

create index nippo_tasks_crop_idx on public.nippo_tasks (crop_id, sort_order);

alter table public.nippo_crops enable row level security;
alter table public.nippo_tasks enable row level security;

create policy "ログイン済みユーザーは日報の作物を閲覧できる"
  on public.nippo_crops for select
  using (auth.role() = 'authenticated');

create policy "管理者は日報の作物を編集できる"
  on public.nippo_crops for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "ログイン済みユーザーは日報の作業を閲覧できる"
  on public.nippo_tasks for select
  using (auth.role() = 'authenticated');

create policy "管理者は日報の作業を編集できる"
  on public.nippo_tasks for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- ── 初期データ（これまでの仮リスト） ──
insert into public.nippo_crops (name, icon, sort_order) values
  ('メロン', '🍈', 1),
  ('スイカ', '🍉', 2),
  ('こかぶ', '🌱', 3),
  ('大根',   '🥬', 4),
  ('その他', '📦', 5);

insert into public.nippo_tasks (crop_id, name, sort_order)
select c.id, t.name, t.ord
from public.nippo_crops c
join (
  select 'メロン' as crop, name, ord from unnest(array['定植','誘引','整枝・摘心','交配','摘果','玉吊り','水やり','消毒','収穫','選果・箱詰め','片付け']) with ordinality as x(name, ord)
  union all
  select 'スイカ', name, ord from unnest(array['定植','整枝・つる引き','交配','摘果','玉直し','水やり','消毒','収穫','選果・出荷','片付け']) with ordinality as x(name, ord)
  union all
  select 'こかぶ', name, ord from unnest(array['畑の準備','種まき','間引き','除草','水やり','消毒','収穫','洗い・袋詰め','出荷']) with ordinality as x(name, ord)
  union all
  select '大根', name, ord from unnest(array['畑の準備','種まき','間引き','除草','追肥','消毒','収穫','洗い・選別','出荷']) with ordinality as x(name, ord)
  union all
  select 'その他', name, ord from unnest(array['草刈り','掃除・片付け','機械の整備','資材の運搬']) with ordinality as x(name, ord)
) t on t.crop = c.name;

-- ── 2. 作業した場所（ハウス／露地 ＋ 番号。番号は「3」「3-2」など自由に書けるよう文字で保存） ──
alter table public.daily_work_entries
  add column location_type text check (location_type in ('ハウス', '露地')),
  add column location_no   text;

-- ── 3. Realtime（すでに対象になっている場合は何もしない） ──
do $$
declare t text;
begin
  foreach t in array array['daily_work_entries', 'attendance_records'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ============================================================
-- 完了！
-- ============================================================
