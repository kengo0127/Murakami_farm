-- ============================================================
-- インスタ・EC注文管理表：消費税率の設定・消費税額の自動計算（2026-09-21）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   すべての単価は税込み（内税）表示のため、単価一覧（melon_price_periods）
--   に「税率」を追加し、期間ごとに何%として税込み計算していたかを
--   記録できるようにする。商品（メロン・スイカ・野菜・玉ねぎ）は
--   軽減税率でデフォルト8%、箱代・送料は標準税率でデフォルト10%。
--   税率は単価と同じく「適用期間」で管理するため、将来税率が変わっても
--   過去に登録した行の消費税額は当時のまま変わらない。
--
--   melon_entries には、行を登録した時点で有効だった税率を保存する列
--   （tax_rate_standard / tax_rate_box_shipping）を追加し、それをもとに
--   消費税額を自動計算する生成列 consumption_tax_amount を追加する。
--   （商品小計・総計は元々すべて税込みで計算済みのため変更不要）
-- ============================================================


-- ============================================================
-- 1. melon_price_periods：税率列の追加（期間ごとに編集可能）
-- ============================================================
alter table public.melon_price_periods add column rate_standard     numeric(5,2) not null default 8;  -- 商品（メロン・スイカ・野菜・玉ねぎ）
alter table public.melon_price_periods add column rate_box_shipping numeric(5,2) not null default 10; -- 箱代・送料


-- ============================================================
-- 2. melon_entries：登録時点の税率を保存する列の追加
--    （既存行はデフォルト値の8%/10%がそのまま設定される。
--     2019年10月の軽減税率導入以降、実際にこの税率だったため妥当）
-- ============================================================
alter table public.melon_entries add column tax_rate_standard     numeric(5,2) not null default 8;
alter table public.melon_entries add column tax_rate_box_shipping numeric(5,2) not null default 10;


-- ============================================================
-- 3. melon_entries：消費税額の生成列を追加
--    内税の税込み金額から税率で逆算する（切り捨て）。
--    「商品小計（8%対象）」と「箱代＋送料（10%対象）」を別々に逆算して合算する。
-- ============================================================
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
-- 完了！
-- 単価一覧パネルに「💰 消費税率」の表が追加され、価格期間ごとに
-- 商品分・箱代/送料分の税率を編集できます（デフォルト8%/10%）。
-- 予約管理表・CSVダウンロードに「消費税」列が追加されます。
-- ============================================================
