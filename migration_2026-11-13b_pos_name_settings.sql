-- ============================================================
-- 店頭会計に表示する商品名を変えられるようにする（2026-11-13）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   インスタ・EC注文管理表の「🏷 商品・価格の設定」→「会計に出る商品名を変える」で、
--   従来の品種（マルセイユ、こかぶ など。画面に組み込まれている商品）の会計での表示名を保存する。
--   注文管理表の列名・Excel・CSVの名前は変わらない（会計の画面だけ）。
--   ※画面から追加した商品（ec_items）は、商品名そのもの（group_label / size_label）を書き換えるため、このテーブルは使わない。
--   name_key：'group:<カテゴリ>:<元の種類名>'（例：'group:veggie:こかぶ'）／'sku:<数量の列名>'（例：'sku:qty_kokabu_kikaku'）
-- ============================================================

create table public.pos_name_settings (
  name_key    text primary key,
  label       text not null,
  updated_at  timestamptz not null default now()
);

alter table public.pos_name_settings enable row level security;

create policy "ログイン済みユーザーは店頭会計の商品名設定を閲覧できる"
  on public.pos_name_settings for select
  using (auth.role() = 'authenticated');

create policy "管理者は店頭会計の商品名設定を編集できる"
  on public.pos_name_settings for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- ============================================================
-- 完了！
-- ============================================================
