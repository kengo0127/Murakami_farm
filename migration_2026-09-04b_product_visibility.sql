-- ============================================================
-- 商品（品種）ごとの表示/非表示設定 マイグレーション（2026-09-04）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   予約管理表（melon_sheet.html）で、今シーズン扱っていない品種を
--   単価一覧・セル編集モーダルから非表示にできるようにする。
--   全期間・全員共通の設定として1つのテーブルで管理する
--   （品種＝MELON_GROUPS等のグループラベル、例：'マルセイユ'）。
-- ============================================================

create table public.melon_product_visibility (
  group_label text primary key,
  visible     boolean not null default true,
  updated_by  uuid references public.profiles(id),
  updated_at  timestamptz not null default now()
);

alter table public.melon_product_visibility enable row level security;

create policy "ログイン済みユーザーは商品表示設定を閲覧できる"
  on public.melon_product_visibility for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ商品表示設定を登録できる"
  on public.melon_product_visibility for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ商品表示設定を更新できる"
  on public.melon_product_visibility for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- 完了！
-- ============================================================
