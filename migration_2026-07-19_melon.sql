-- ============================================================
-- 村上農園 メロン・インスタ予約販売管理表 マイグレーション（2026-07-19）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================


-- ============================================================
-- 1. customers（顧客マスタ／あ行〜わ行タップ選択の候補リスト）
-- ============================================================
create table public.customers (
  id         uuid primary key default gen_random_uuid(),
  kana_row   text not null check (kana_row in ('あ','か','さ','た','な','は','ま','や','ら','わ')),
  name       text not null,
  created_at timestamptz not null default now(),
  unique (kana_row, name)
);

create index on public.customers (kana_row);


-- ============================================================
-- 2. melon_sheets（月次シート）
-- ============================================================
create table public.melon_sheets (
  id         uuid primary key default gen_random_uuid(),
  year       integer not null check (year between 2020 and 2100),
  month      integer not null check (month between 1 and 12),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (year, month)
);


-- ============================================================
-- 3. melon_entries（注文明細＝表の1行）
-- ============================================================
create table public.melon_entries (
  id                uuid primary key default gen_random_uuid(),
  sheet_id          uuid not null references public.melon_sheets(id) on delete cascade,
  sort_order        integer not null default 0,

  entry_date        date,                       -- 日付（曜日はフロントで算出）
  customer_name     text not null default '',   -- お名前

  qty_3l            integer not null default 0 check (qty_3l >= 0),
  qty_4l            integer not null default 0 check (qty_4l >= 0),
  qty_5l            integer not null default 0 check (qty_5l >= 0),
  qty_other         integer not null default 0 check (qty_other >= 0),
  other_label       text,                       -- 「その他」の内容メモ（任意）

  unit_price_3l     integer not null default 1000,
  unit_price_4l     integer not null default 1100,
  unit_price_5l     integer not null default 1200,
  unit_price_other  integer not null default 0, -- その他は基本単価なし＝都度入力

  onion_kg          numeric(6,2) not null default 0 check (onion_kg >= 0),
  onion_unit_price  integer not null default 280,

  box_2             integer not null default 0 check (box_2 >= 0),  -- 2玉入
  box_35            integer not null default 0 check (box_35 >= 0), -- 3〜5玉入
  box_unit_price_2  integer not null default 250,
  box_unit_price_35 integer not null default 350,

  shipping_fee      integer not null default 0, -- 送料（自由入力）

  shipped           boolean not null default false, -- 発送
  paid              boolean not null default false,  -- 入金
  receipt_issued    boolean not null default false,  -- 領収書

  note              text,                       -- 備考

  -- 商品小計（3L/4L/5L/その他/玉ねぎ）
  subtotal_amount   integer generated always as (
                       qty_3l * unit_price_3l
                       + qty_4l * unit_price_4l
                       + qty_5l * unit_price_5l
                       + qty_other * unit_price_other
                       + round(onion_kg * onion_unit_price)::integer
                     ) stored,

  -- 箱代＋送料込みの総計
  total_amount      integer generated always as (
                       qty_3l * unit_price_3l
                       + qty_4l * unit_price_4l
                       + qty_5l * unit_price_5l
                       + qty_other * unit_price_other
                       + round(onion_kg * onion_unit_price)::integer
                       + box_2 * box_unit_price_2
                       + box_35 * box_unit_price_35
                       + shipping_fee
                     ) stored,

  created_by        uuid references public.profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index on public.melon_entries (sheet_id);

-- 更新時刻を自動更新するトリガー
create or replace function public.set_melon_entries_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_melon_entries_updated_at
  before update on public.melon_entries
  for each row execute procedure public.set_melon_entries_updated_at();


-- ============================================================
-- 4. RLS（管理者のみ全操作可）
-- ============================================================
alter table public.customers enable row level security;
alter table public.melon_sheets enable row level security;
alter table public.melon_entries enable row level security;

create policy "管理者は顧客マスタを閲覧できる" on public.customers for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は顧客マスタを登録できる" on public.customers for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は顧客マスタを更新できる" on public.customers for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は顧客マスタを削除できる" on public.customers for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者は月次シートを閲覧できる" on public.melon_sheets for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は月次シートを作成できる" on public.melon_sheets for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は月次シートを削除できる" on public.melon_sheets for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者は明細を閲覧できる" on public.melon_entries for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は明細を登録できる" on public.melon_entries for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は明細を更新できる" on public.melon_entries for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "管理者は明細を削除できる" on public.melon_entries for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));


-- ============================================================
-- 完了！
-- 次のステップ：seed_customers.sql を実行して顧客マスタを投入
-- ============================================================
