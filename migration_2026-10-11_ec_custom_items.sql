-- ============================================================
-- インスタ・EC：画面から商品・サイズ・単位・まとめ買い価格を追加できるようにする（2026-10-11）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   これまで商品を1つ追加するたびに、DB列の追加・JSの書き換えが必要だった。
--   今後は予約管理表の「🏷 商品・価格の設定」から、管理者が自分で商品を追加できるようにする。
--   （既存の商品・DB列はそのまま使い続ける。お客様向け注文フォームは今回は対象外）
--
--   1. ec_items       ：追加した商品（品物の区分・品名・サイズ名・単位・販売中か）
--   2. ec_item_prices ：その商品の価格（適用日ごと）と、まとめ買い価格（例：2玉で500円）
--   3. melon_entries  ：追加商品の明細（extra_items）と合計金額（extra_items_amount）の列を追加し、
--                       商品小計・総計・消費税の計算式に extra_items_amount を足す
--   4. 初期データ     ：かぼちゃ 1玉 300円（2玉で500円）
-- ============================================================


-- ============================================================
-- 1. ec_items：追加した商品
-- ============================================================
create table public.ec_items (
  id          uuid primary key default gen_random_uuid(),
  category    text not null check (category in ('melon', 'suika', 'veggie')),
  group_label text not null,             -- 品名（例：かぼちゃ）。既存の品種と同じ名前なら、画面上は同じ種類の中に並ぶ
  size_label  text not null default '',  -- サイズ・規格（例：1玉、L、規格外）。空でもよい
  unit        text not null default '個', -- 単位（玉／本／袋／kg など。kg は小数の量り売り）
  active      boolean not null default true, -- false＝販売停止（過去の記録は残る）
  sort_order  integer not null default 0,
  created_by  uuid references public.profiles(id),
  created_at  timestamptz not null default now()
);

alter table public.ec_items enable row level security;

create policy "誰でも追加商品を閲覧できる" on public.ec_items for select
  to anon, authenticated
  using (true);

create policy "管理者のみ追加商品を登録できる" on public.ec_items for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者のみ追加商品を更新できる" on public.ec_items for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者のみ追加商品を削除できる" on public.ec_items for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));


-- ============================================================
-- 2. ec_item_prices：追加商品の価格（適用日ごと）
--    ある日付の価格は「その日付以前で最も新しい start_date」の行を使う
--    （kintai_hourly_wages と同じ考え方。月ごとの表には属さない）
-- ============================================================
create table public.ec_item_prices (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid not null references public.ec_items(id) on delete cascade,
  start_date  date not null,
  unit_price  integer not null check (unit_price >= 0), -- 1単位あたりの税込み価格
  bundles     jsonb not null default '[]'::jsonb,       -- まとめ買い価格 [{"qty":2,"price":500}, ...]
  created_by  uuid references public.profiles(id),
  created_at  timestamptz not null default now(),
  unique (item_id, start_date)
);

alter table public.ec_item_prices enable row level security;

create policy "誰でも追加商品の価格を閲覧できる" on public.ec_item_prices for select
  to anon, authenticated
  using (true);

create policy "管理者のみ追加商品の価格を登録できる" on public.ec_item_prices for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者のみ追加商品の価格を更新できる" on public.ec_item_prices for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者のみ追加商品の価格を削除できる" on public.ec_item_prices for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));


-- ============================================================
-- 3. melon_entries：追加商品の明細・金額の列
--    extra_items には登録時点の品名・単価・まとめ買い価格・金額をスナップショットで保存する
--    （あとで商品の価格を変えても、過去の行の金額は変わらない）
-- ============================================================
alter table public.melon_entries add column extra_items jsonb not null default '[]'::jsonb;
alter table public.melon_entries add column extra_items_amount integer not null default 0 check (extra_items_amount >= 0);

-- 生成列は式を直接変更できないため drop → 再作成（追加商品は商品扱いで8%側に含める）
alter table public.melon_entries drop column subtotal_amount;
alter table public.melon_entries drop column total_amount;
alter table public.melon_entries drop column consumption_tax_amount;

alter table public.melon_entries add column subtotal_amount integer generated always as (
  qty_3l * unit_price_3l + qty_4l * unit_price_4l + qty_5l * unit_price_5l
  + qty_arusu_l * unit_price_arusu_l + qty_arusu_2l * unit_price_arusu_2l + qty_arusu_3l * unit_price_arusu_3l
  + qty_arusu_4l * unit_price_arusu_4l + qty_arusu_5l * unit_price_arusu_5l
  + qty_andes_3l * unit_price_andes_3l + qty_andes_4l * unit_price_andes_4l + qty_andes_5l * unit_price_andes_5l
  + qty_yogurkiss_m * unit_price_yogurkiss_m + qty_yogurkiss_l * unit_price_yogurkiss_l
  + qty_pure_normal * unit_price_pure_normal + qty_pure_large * unit_price_pure_large + qty_pure_xlarge * unit_price_pure_xlarge
  + qty_hiyake * unit_price_hiyake
  + qty_sakusaku_m * unit_price_sakusaku_m + qty_sakusaku_l * unit_price_sakusaku_l
  + qty_suika_wake_s * unit_price_suika_wake_s + qty_suika_wake_m * unit_price_suika_wake_m
  + qty_suika_wake_l * unit_price_suika_wake_l + qty_suika_wake_2l * unit_price_suika_wake_2l
  + qty_suika_wake_3l * unit_price_suika_wake_3l + qty_suika_wake_4l * unit_price_suika_wake_4l
  + qty_suika_wake_5l * unit_price_suika_wake_5l
  + qty_suika_regular_2l * unit_price_suika_regular_2l + qty_suika_regular_3l * unit_price_suika_regular_3l
  + qty_suika_regular_4l * unit_price_suika_regular_4l
  + qty_kokabu_kikaku * unit_price_kokabu_kikaku + qty_kokabu_naka * unit_price_kokabu_naka
  + qty_daikon_s * unit_price_daikon_s + qty_daikon_m * unit_price_daikon_m
  + qty_daikon_l * unit_price_daikon_l + qty_daikon_2l * unit_price_daikon_2l
  + qty_daikon_kiri * unit_price_daikon_kiri
  + qty_kabocha_kikaku * unit_price_kabocha_kikaku
  + qty_ninjin_kikaku * unit_price_ninjin_kikaku
  + qty_other * unit_price_other
  + round(onion_kg * onion_unit_price)::integer
  + extra_items_amount
) stored;

alter table public.melon_entries add column total_amount integer generated always as (
  qty_3l * unit_price_3l + qty_4l * unit_price_4l + qty_5l * unit_price_5l
  + qty_arusu_l * unit_price_arusu_l + qty_arusu_2l * unit_price_arusu_2l + qty_arusu_3l * unit_price_arusu_3l
  + qty_arusu_4l * unit_price_arusu_4l + qty_arusu_5l * unit_price_arusu_5l
  + qty_andes_3l * unit_price_andes_3l + qty_andes_4l * unit_price_andes_4l + qty_andes_5l * unit_price_andes_5l
  + qty_yogurkiss_m * unit_price_yogurkiss_m + qty_yogurkiss_l * unit_price_yogurkiss_l
  + qty_pure_normal * unit_price_pure_normal + qty_pure_large * unit_price_pure_large + qty_pure_xlarge * unit_price_pure_xlarge
  + qty_hiyake * unit_price_hiyake
  + qty_sakusaku_m * unit_price_sakusaku_m + qty_sakusaku_l * unit_price_sakusaku_l
  + qty_suika_wake_s * unit_price_suika_wake_s + qty_suika_wake_m * unit_price_suika_wake_m
  + qty_suika_wake_l * unit_price_suika_wake_l + qty_suika_wake_2l * unit_price_suika_wake_2l
  + qty_suika_wake_3l * unit_price_suika_wake_3l + qty_suika_wake_4l * unit_price_suika_wake_4l
  + qty_suika_wake_5l * unit_price_suika_wake_5l
  + qty_suika_regular_2l * unit_price_suika_regular_2l + qty_suika_regular_3l * unit_price_suika_regular_3l
  + qty_suika_regular_4l * unit_price_suika_regular_4l
  + qty_kokabu_kikaku * unit_price_kokabu_kikaku + qty_kokabu_naka * unit_price_kokabu_naka
  + qty_daikon_s * unit_price_daikon_s + qty_daikon_m * unit_price_daikon_m
  + qty_daikon_l * unit_price_daikon_l + qty_daikon_2l * unit_price_daikon_2l
  + qty_daikon_kiri * unit_price_daikon_kiri
  + qty_kabocha_kikaku * unit_price_kabocha_kikaku
  + qty_ninjin_kikaku * unit_price_ninjin_kikaku
  + qty_other * unit_price_other
  + round(onion_kg * onion_unit_price)::integer
  + extra_items_amount
  + box_2 * box_unit_price_2 + box_35 * box_unit_price_35
  + box_suika_1 * box_unit_price_suika_1 + box_suika_2 * box_unit_price_suika_2 + box_suika_plain * box_unit_price_suika_plain
  + shipping_fee
) stored;

alter table public.melon_entries add column consumption_tax_amount integer generated always as (
  floor(
    (
      qty_3l * unit_price_3l + qty_4l * unit_price_4l + qty_5l * unit_price_5l
      + qty_arusu_l * unit_price_arusu_l + qty_arusu_2l * unit_price_arusu_2l + qty_arusu_3l * unit_price_arusu_3l
      + qty_arusu_4l * unit_price_arusu_4l + qty_arusu_5l * unit_price_arusu_5l
      + qty_andes_3l * unit_price_andes_3l + qty_andes_4l * unit_price_andes_4l + qty_andes_5l * unit_price_andes_5l
      + qty_yogurkiss_m * unit_price_yogurkiss_m + qty_yogurkiss_l * unit_price_yogurkiss_l
      + qty_pure_normal * unit_price_pure_normal + qty_pure_large * unit_price_pure_large + qty_pure_xlarge * unit_price_pure_xlarge
      + qty_hiyake * unit_price_hiyake
      + qty_sakusaku_m * unit_price_sakusaku_m + qty_sakusaku_l * unit_price_sakusaku_l
      + qty_suika_wake_s * unit_price_suika_wake_s + qty_suika_wake_m * unit_price_suika_wake_m
      + qty_suika_wake_l * unit_price_suika_wake_l + qty_suika_wake_2l * unit_price_suika_wake_2l
      + qty_suika_wake_3l * unit_price_suika_wake_3l + qty_suika_wake_4l * unit_price_suika_wake_4l
      + qty_suika_wake_5l * unit_price_suika_wake_5l
      + qty_suika_regular_2l * unit_price_suika_regular_2l + qty_suika_regular_3l * unit_price_suika_regular_3l
      + qty_suika_regular_4l * unit_price_suika_regular_4l
      + qty_kokabu_kikaku * unit_price_kokabu_kikaku + qty_kokabu_naka * unit_price_kokabu_naka
      + qty_daikon_s * unit_price_daikon_s + qty_daikon_m * unit_price_daikon_m
      + qty_daikon_l * unit_price_daikon_l + qty_daikon_2l * unit_price_daikon_2l
      + qty_daikon_kiri * unit_price_daikon_kiri
      + qty_kabocha_kikaku * unit_price_kabocha_kikaku
      + qty_ninjin_kikaku * unit_price_ninjin_kikaku
      + qty_other * unit_price_other
      + round(onion_kg * onion_unit_price)::integer
      + extra_items_amount
    )::numeric * tax_rate_standard / (100 + tax_rate_standard)
  )::integer
  +
  floor(
    (
      box_2 * box_unit_price_2 + box_35 * box_unit_price_35
      + box_suika_1 * box_unit_price_suika_1 + box_suika_2 * box_unit_price_suika_2 + box_suika_plain * box_unit_price_suika_plain
      + shipping_fee
    )::numeric * tax_rate_box_shipping / (100 + tax_rate_box_shipping)
  )::integer
) stored;


-- ============================================================
-- 4. 初期データ：かぼちゃ 1玉 300円（2玉で500円）
--    既存の「かぼちゃ 規格外(100g)」はそのまま残る。使わない場合は
--    単価一覧の「かぼちゃ」ボタンで非表示にしてください（追加商品の「1玉」は非表示になりません）
-- ============================================================
with new_item as (
  insert into public.ec_items (category, group_label, size_label, unit, sort_order)
  values ('veggie', 'かぼちゃ', '1玉', '玉', 1)
  returning id
)
insert into public.ec_item_prices (item_id, start_date, unit_price, bundles)
select id, date '2026-10-01', 300, '[{"qty":2,"price":500}]'::jsonb from new_item;

-- ============================================================
-- 完了！
-- 予約管理表のツールバーに「🏷 商品・価格の設定」ボタンが使えるようになります。
-- ============================================================
