-- ============================================================
-- 作業日報の「場所」を複数選べるようにし、番号を管理者が編集できるようにする（2026-11-13）
-- migration_2026-11-09b_nippo_places.sql の後に実行してください
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. 場所ごとの番号リスト（ハウス1〜83、露地の区画 など）を nippo_place_numbers で管理する。
--      管理画面「作業日報 → 日報を編集する」から追加・名前の変更・削除・並べ替えができる。
--      スタッフは番号をボタンで選ぶ（リストにない番号は手入力もできる）。
--   2. 1つの作業で複数の場所を選べるよう、daily_work_entries に places（jsonb）を追加する。
--      形式：[{"place":"ハウス","no":"3"}, {"place":"ハウス","no":"5"}, {"place":"その他","no":null}]
--      これまでの location_type / location_no は古い日報の表示用にそのまま残す（新しい日報では空）。
--   ※番号の名前を変えても、登録済みの日報は保存したときの番号のまま残る。
-- ============================================================

-- ── 1. 場所ごとの番号リスト ──
create table public.nippo_place_numbers (
  id          uuid primary key default gen_random_uuid(),
  place_id    uuid not null references public.nippo_places(id) on delete cascade,
  label       text not null,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  unique (place_id, label)
);

create index nippo_place_numbers_place_idx on public.nippo_place_numbers (place_id, sort_order);

alter table public.nippo_place_numbers enable row level security;

create policy "ログイン済みユーザーは日報の場所番号を閲覧できる"
  on public.nippo_place_numbers for select
  using (auth.role() = 'authenticated');

create policy "管理者は日報の場所番号を編集できる"
  on public.nippo_place_numbers for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 初期データ：ハウスは 1〜83（作業指示の画面と同じ）
insert into public.nippo_place_numbers (place_id, label, sort_order)
select p.id, n::text, n
from public.nippo_places p, generate_series(1, 83) as n
where p.name = 'ハウス'
on conflict do nothing;

-- 初期データ：露地は、作業指示で使っている露地マップの区画名（field_plots）があればそれを入れる
do $$
begin
  if to_regclass('public.field_plots') is not null then
    insert into public.nippo_place_numbers (place_id, label, sort_order)
    select p.id, f.label, row_number() over (
             order by case when f.label ~ '^[0-9]+$' then f.label::int end nulls last, f.label)
    from public.nippo_places p,
         (select distinct label from public.field_plots where coalesce(label, '') <> '') f
    where p.name = '露地'
    on conflict do nothing;
  end if;
end $$;

-- ── 2. 日報に複数の場所を保存する列 ──
alter table public.daily_work_entries
  add column if not exists places jsonb;

-- ============================================================
-- 完了！
-- ============================================================
