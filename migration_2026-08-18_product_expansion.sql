-- ============================================================
-- 村上農園 インスタ・EC注文管理表 商品拡張マイグレーション（2026-08-18）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   melon_entries / melon_price_periods に、メロン各品種・スイカ・野菜の
--   数量／単価列を追加し、商品小計・総計の計算式を再作成する
--   （既存の qty_3l/4l/5l 等はそのまま「マルセイユメロン」として使用）
-- ============================================================


-- ============================================================
-- 1. melon_entries：数量・単価列の追加
-- ============================================================

-- ── メロン：アンデス ──
alter table public.melon_entries add column qty_andes_3l integer not null default 0 check (qty_andes_3l >= 0);
alter table public.melon_entries add column qty_andes_4l integer not null default 0 check (qty_andes_4l >= 0);
alter table public.melon_entries add column qty_andes_5l integer not null default 0 check (qty_andes_5l >= 0);
alter table public.melon_entries add column unit_price_andes_3l integer not null default 1000;
alter table public.melon_entries add column unit_price_andes_4l integer not null default 1100;
alter table public.melon_entries add column unit_price_andes_5l integer not null default 1200;

-- ── メロン：ヨーグルキッス（中／大） ──
alter table public.melon_entries add column qty_yogurkiss_m integer not null default 0 check (qty_yogurkiss_m >= 0);
alter table public.melon_entries add column qty_yogurkiss_l integer not null default 0 check (qty_yogurkiss_l >= 0);
alter table public.melon_entries add column unit_price_yogurkiss_m integer not null default 300;
alter table public.melon_entries add column unit_price_yogurkiss_l integer not null default 500;

-- ── メロン：ピュアリモーネ（並／大／特大） ──
alter table public.melon_entries add column qty_pure_normal integer not null default 0 check (qty_pure_normal >= 0);
alter table public.melon_entries add column qty_pure_large integer not null default 0 check (qty_pure_large >= 0);
alter table public.melon_entries add column qty_pure_xlarge integer not null default 0 check (qty_pure_xlarge >= 0);
alter table public.melon_entries add column unit_price_pure_normal integer not null default 1000;
alter table public.melon_entries add column unit_price_pure_large integer not null default 1100;
alter table public.melon_entries add column unit_price_pure_xlarge integer not null default 1100;

-- ── メロン：日焼け（ハネ） ──
alter table public.melon_entries add column qty_hiyake integer not null default 0 check (qty_hiyake >= 0);
alter table public.melon_entries add column unit_price_hiyake integer not null default 800;

-- ── メロン：サクサクハミー（中／大） ──
alter table public.melon_entries add column qty_sakusaku_m integer not null default 0 check (qty_sakusaku_m >= 0);
alter table public.melon_entries add column qty_sakusaku_l integer not null default 0 check (qty_sakusaku_l >= 0);
alter table public.melon_entries add column unit_price_sakusaku_m integer not null default 600;
alter table public.melon_entries add column unit_price_sakusaku_l integer not null default 800;

-- ── スイカ：訳あり ──
alter table public.melon_entries add column qty_suika_wake_s  integer not null default 0 check (qty_suika_wake_s  >= 0);
alter table public.melon_entries add column qty_suika_wake_m  integer not null default 0 check (qty_suika_wake_m  >= 0);
alter table public.melon_entries add column qty_suika_wake_l  integer not null default 0 check (qty_suika_wake_l  >= 0);
alter table public.melon_entries add column qty_suika_wake_2l integer not null default 0 check (qty_suika_wake_2l >= 0);
alter table public.melon_entries add column qty_suika_wake_3l integer not null default 0 check (qty_suika_wake_3l >= 0);
alter table public.melon_entries add column qty_suika_wake_4l integer not null default 0 check (qty_suika_wake_4l >= 0);
alter table public.melon_entries add column qty_suika_wake_5l integer not null default 0 check (qty_suika_wake_5l >= 0);
alter table public.melon_entries add column unit_price_suika_wake_s  integer not null default 1000;
alter table public.melon_entries add column unit_price_suika_wake_m  integer not null default 1200;
alter table public.melon_entries add column unit_price_suika_wake_l  integer not null default 1400;
alter table public.melon_entries add column unit_price_suika_wake_2l integer not null default 1600;
alter table public.melon_entries add column unit_price_suika_wake_3l integer not null default 2000;
alter table public.melon_entries add column unit_price_suika_wake_4l integer not null default 2200;
alter table public.melon_entries add column unit_price_suika_wake_5l integer not null default 2500;

-- ── スイカ：正規品 ──
alter table public.melon_entries add column qty_suika_regular_2l integer not null default 0 check (qty_suika_regular_2l >= 0);
alter table public.melon_entries add column qty_suika_regular_3l integer not null default 0 check (qty_suika_regular_3l >= 0);
alter table public.melon_entries add column qty_suika_regular_4l integer not null default 0 check (qty_suika_regular_4l >= 0);
alter table public.melon_entries add column unit_price_suika_regular_2l integer not null default 2300;
alter table public.melon_entries add column unit_price_suika_regular_3l integer not null default 2500;
alter table public.melon_entries add column unit_price_suika_regular_4l integer not null default 2800;

-- ── スイカ：箱代 ──
alter table public.melon_entries add column box_suika_1     integer not null default 0 check (box_suika_1 >= 0);
alter table public.melon_entries add column box_suika_2     integer not null default 0 check (box_suika_2 >= 0);
alter table public.melon_entries add column box_suika_plain integer not null default 0 check (box_suika_plain >= 0);
alter table public.melon_entries add column box_unit_price_suika_1     integer not null default 200;
alter table public.melon_entries add column box_unit_price_suika_2     integer not null default 300;
alter table public.melon_entries add column box_unit_price_suika_plain integer not null default 250;

-- ── 野菜：こかぶ ──
alter table public.melon_entries add column qty_kokabu_kikaku integer not null default 0 check (qty_kokabu_kikaku >= 0); -- 規格外こかぶ 10玉1セット
alter table public.melon_entries add column qty_kokabu_naka   integer not null default 0 check (qty_kokabu_naka >= 0);   -- 中かぶ 1玉
alter table public.melon_entries add column unit_price_kokabu_kikaku integer not null default 400;
alter table public.melon_entries add column unit_price_kokabu_naka   integer not null default 55;

-- ── 野菜：大根 ──
alter table public.melon_entries add column qty_daikon_s  integer not null default 0 check (qty_daikon_s  >= 0);
alter table public.melon_entries add column qty_daikon_m  integer not null default 0 check (qty_daikon_m  >= 0);
alter table public.melon_entries add column qty_daikon_l  integer not null default 0 check (qty_daikon_l  >= 0);
alter table public.melon_entries add column qty_daikon_2l integer not null default 0 check (qty_daikon_2l >= 0);
alter table public.melon_entries add column unit_price_daikon_s  integer not null default 120;
alter table public.melon_entries add column unit_price_daikon_m  integer not null default 130;
alter table public.melon_entries add column unit_price_daikon_l  integer not null default 170;
alter table public.melon_entries add column unit_price_daikon_2l integer not null default 190;

-- ── 野菜：切り大根 ──
alter table public.melon_entries add column qty_daikon_kiri integer not null default 0 check (qty_daikon_kiri >= 0); -- 1kg
alter table public.melon_entries add column unit_price_daikon_kiri integer not null default 100;

-- ── 野菜：かぼちゃ ──
alter table public.melon_entries add column qty_kabocha_kikaku integer not null default 0 check (qty_kabocha_kikaku >= 0); -- 規格外 100g
alter table public.melon_entries add column unit_price_kabocha_kikaku integer not null default 35;

-- ── 野菜：にんじん ──
alter table public.melon_entries add column qty_ninjin_kikaku integer not null default 0 check (qty_ninjin_kikaku >= 0); -- 規格外 10kg
alter table public.melon_entries add column unit_price_ninjin_kikaku integer not null default 1080;


-- ============================================================
-- 2. melon_entries：subtotal_amount / total_amount の再作成
--    （generated column は式を直接変更できないため drop → 再作成）
-- ============================================================
alter table public.melon_entries drop column subtotal_amount;
alter table public.melon_entries drop column total_amount;

alter table public.melon_entries add column subtotal_amount integer generated always as (
  qty_3l * unit_price_3l + qty_4l * unit_price_4l + qty_5l * unit_price_5l
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
alter table public.melon_price_periods add column price_andes_3l integer not null default 1000;
alter table public.melon_price_periods add column price_andes_4l integer not null default 1100;
alter table public.melon_price_periods add column price_andes_5l integer not null default 1200;

alter table public.melon_price_periods add column price_yogurkiss_m integer not null default 300;
alter table public.melon_price_periods add column price_yogurkiss_l integer not null default 500;

alter table public.melon_price_periods add column price_pure_normal integer not null default 1000;
alter table public.melon_price_periods add column price_pure_large  integer not null default 1100;
alter table public.melon_price_periods add column price_pure_xlarge integer not null default 1100;

alter table public.melon_price_periods add column price_hiyake integer not null default 800;

alter table public.melon_price_periods add column price_sakusaku_m integer not null default 600;
alter table public.melon_price_periods add column price_sakusaku_l integer not null default 800;

alter table public.melon_price_periods add column price_suika_wake_s  integer not null default 1000;
alter table public.melon_price_periods add column price_suika_wake_m  integer not null default 1200;
alter table public.melon_price_periods add column price_suika_wake_l  integer not null default 1400;
alter table public.melon_price_periods add column price_suika_wake_2l integer not null default 1600;
alter table public.melon_price_periods add column price_suika_wake_3l integer not null default 2000;
alter table public.melon_price_periods add column price_suika_wake_4l integer not null default 2200;
alter table public.melon_price_periods add column price_suika_wake_5l integer not null default 2500;

alter table public.melon_price_periods add column price_suika_regular_2l integer not null default 2300;
alter table public.melon_price_periods add column price_suika_regular_3l integer not null default 2500;
alter table public.melon_price_periods add column price_suika_regular_4l integer not null default 2800;

alter table public.melon_price_periods add column price_box_suika_1     integer not null default 200;
alter table public.melon_price_periods add column price_box_suika_2     integer not null default 300;
alter table public.melon_price_periods add column price_box_suika_plain integer not null default 250;

alter table public.melon_price_periods add column price_kokabu_kikaku integer not null default 400;
alter table public.melon_price_periods add column price_kokabu_naka   integer not null default 55;

alter table public.melon_price_periods add column price_daikon_s  integer not null default 120;
alter table public.melon_price_periods add column price_daikon_m  integer not null default 130;
alter table public.melon_price_periods add column price_daikon_l  integer not null default 170;
alter table public.melon_price_periods add column price_daikon_2l integer not null default 190;

alter table public.melon_price_periods add column price_daikon_kiri integer not null default 100;

alter table public.melon_price_periods add column price_kabocha_kikaku integer not null default 35;

alter table public.melon_price_periods add column price_ninjin_kikaku integer not null default 1080;

-- ============================================================
-- 完了！
-- ============================================================
