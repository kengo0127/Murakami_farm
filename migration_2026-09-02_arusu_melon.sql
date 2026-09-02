-- ============================================================
-- 村上農園 インスタ・EC注文管理表 商品拡張マイグレーション（2026-09-02）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   新しい作物「アールスメロン」（L/2L/3L）を追加する。
--   melon_entries / melon_price_periods に数量・単価列を追加し、
--   商品小計・総計の計算式を再作成する。
--   お客様向け注文フォームからも注文できるよう、
--   melon_order_requests にも同じ列を追加する。
-- ============================================================


-- ============================================================
-- 1. melon_entries：数量・単価列の追加
-- ============================================================

-- ── メロン：アールス ──
alter table public.melon_entries add column qty_arusu_l  integer not null default 0 check (qty_arusu_l  >= 0);
alter table public.melon_entries add column qty_arusu_2l integer not null default 0 check (qty_arusu_2l >= 0);
alter table public.melon_entries add column qty_arusu_3l integer not null default 0 check (qty_arusu_3l >= 0);
alter table public.melon_entries add column unit_price_arusu_l  integer not null default 1000;
alter table public.melon_entries add column unit_price_arusu_2l integer not null default 1100;
alter table public.melon_entries add column unit_price_arusu_3l integer not null default 1200;


-- ============================================================
-- 2. melon_entries：subtotal_amount / total_amount の再作成
--    （generated column は式を直接変更できないため drop → 再作成）
-- ============================================================
alter table public.melon_entries drop column subtotal_amount;
alter table public.melon_entries drop column total_amount;

alter table public.melon_entries add column subtotal_amount integer generated always as (
  qty_3l * unit_price_3l + qty_4l * unit_price_4l + qty_5l * unit_price_5l
  + qty_arusu_l * unit_price_arusu_l + qty_arusu_2l * unit_price_arusu_2l + qty_arusu_3l * unit_price_arusu_3l
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
alter table public.melon_price_periods add column price_arusu_l  integer not null default 1000;
alter table public.melon_price_periods add column price_arusu_2l integer not null default 1100;
alter table public.melon_price_periods add column price_arusu_3l integer not null default 1200;


-- ============================================================
-- 4. melon_order_requests：お客様向け注文フォームでも
--    アールスメロンを注文できるようにする
-- ============================================================
alter table public.melon_order_requests add column qty_arusu_l  integer not null default 0 check (qty_arusu_l  >= 0);
alter table public.melon_order_requests add column qty_arusu_2l integer not null default 0 check (qty_arusu_2l >= 0);
alter table public.melon_order_requests add column qty_arusu_3l integer not null default 0 check (qty_arusu_3l >= 0);

-- ============================================================
-- 完了！
-- ============================================================
