-- ============================================================
-- 村上農園 インスタ・EC注文管理表 商品拡張マイグレーション（2026-09-04）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   アールスメロンのサイズラインナップに 4L（1,300円）・5L（1,400円）
--   を追加する。melon_entries / melon_price_periods / melon_order_requests
--   に数量・単価列を追加し、商品小計・総計の計算式を再作成する。
-- ============================================================


-- ============================================================
-- 1. melon_entries：数量・単価列の追加
-- ============================================================
alter table public.melon_entries add column qty_arusu_4l integer not null default 0 check (qty_arusu_4l >= 0);
alter table public.melon_entries add column qty_arusu_5l integer not null default 0 check (qty_arusu_5l >= 0);
alter table public.melon_entries add column unit_price_arusu_4l integer not null default 1300;
alter table public.melon_entries add column unit_price_arusu_5l integer not null default 1400;


-- ============================================================
-- 2. melon_entries：subtotal_amount / total_amount の再作成
--    （generated column は式を直接変更できないため drop → 再作成）
-- ============================================================
alter table public.melon_entries drop column subtotal_amount;
alter table public.melon_entries drop column total_amount;

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
  + box_2 * box_unit_price_2 + box_35 * box_unit_price_35
  + box_suika_1 * box_unit_price_suika_1 + box_suika_2 * box_unit_price_suika_2 + box_suika_plain * box_unit_price_suika_plain
  + shipping_fee
) stored;


-- ============================================================
-- 3. melon_price_periods：対応する単価列の追加
-- ============================================================
alter table public.melon_price_periods add column price_arusu_4l integer not null default 1300;
alter table public.melon_price_periods add column price_arusu_5l integer not null default 1400;


-- ============================================================
-- 4. melon_order_requests：お客様向け注文フォームでも
--    アールスメロン4L/5Lを注文できるようにする
-- ============================================================
alter table public.melon_order_requests add column qty_arusu_4l integer not null default 0 check (qty_arusu_4l >= 0);
alter table public.melon_order_requests add column qty_arusu_5l integer not null default 0 check (qty_arusu_5l >= 0);

alter table public.melon_order_requests drop constraint melon_order_requests_qty_check;
alter table public.melon_order_requests add constraint melon_order_requests_qty_check check (
  qty_3l + qty_4l + qty_5l + qty_other
  + qty_arusu_l + qty_arusu_2l + qty_arusu_3l + qty_arusu_4l + qty_arusu_5l
  + qty_kokabu_kikaku + qty_kokabu_naka
  + qty_daikon_s + qty_daikon_m + qty_daikon_l + qty_daikon_2l + qty_daikon_kiri
  + qty_kabocha_kikaku + qty_ninjin_kikaku > 0
  or onion_kg > 0
);

-- ============================================================
-- 完了！
-- ============================================================
