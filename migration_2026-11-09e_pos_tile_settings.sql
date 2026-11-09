-- ============================================================
-- 店頭会計：品物アイコンの表示・非表示とアイコンの設定（2026-11-09）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   店頭会計の「品物」に、野菜の各作物（こかぶ・大根・トマト…）をメロン・スイカと並べて出すようにしたため、
--   アイコンが増えて探しにくくなった。使わない品物のアイコンを非表示にしたり、
--   絵文字が合わない品物（例：かき）のアイコンを変えたりできるようにする。
--   設定はPC・スマホなど全端末で共通。
--   tile_key：'melon' / 'suika' / 'onion' / 'veggie:品名'（例：'veggie:トマト'）
-- ============================================================

create table public.pos_tile_settings (
  tile_key    text primary key,
  hidden      boolean not null default false,
  icon        text,                      -- null＝自動（品名から推測）
  updated_at  timestamptz not null default now()
);

alter table public.pos_tile_settings enable row level security;

create policy "ログイン済みユーザーは店頭会計のアイコン設定を閲覧できる"
  on public.pos_tile_settings for select
  using (auth.role() = 'authenticated');

create policy "管理者は店頭会計のアイコン設定を編集できる"
  on public.pos_tile_settings for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- ============================================================
-- 完了！
-- ============================================================
