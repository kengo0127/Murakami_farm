-- ============================================================
-- お客様向け注文フォーム拡張マイグレーション（2026-09-03）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. melon_order_requests に野菜（こかぶ／大根／かぼちゃ／にんじん）
--      の数量列を追加し、お客様向けフォームからも注文できるようにする
--   2. ご連絡先を「インスタ」「メールまたは電話」の選択式に変更する
--      ための contact_type 列を追加する
--   3. 数量チェック制約（1品目以上の注文を必須にするもの）に
--      野菜の数量も含めて再作成する
-- ============================================================

-- ── 野菜：こかぶ ──
alter table public.melon_order_requests add column qty_kokabu_kikaku integer not null default 0 check (qty_kokabu_kikaku >= 0);
alter table public.melon_order_requests add column qty_kokabu_naka   integer not null default 0 check (qty_kokabu_naka   >= 0);

-- ── 野菜：大根 ──
alter table public.melon_order_requests add column qty_daikon_s  integer not null default 0 check (qty_daikon_s  >= 0);
alter table public.melon_order_requests add column qty_daikon_m  integer not null default 0 check (qty_daikon_m  >= 0);
alter table public.melon_order_requests add column qty_daikon_l  integer not null default 0 check (qty_daikon_l  >= 0);
alter table public.melon_order_requests add column qty_daikon_2l integer not null default 0 check (qty_daikon_2l >= 0);

-- ── 野菜：切り大根 ──
alter table public.melon_order_requests add column qty_daikon_kiri integer not null default 0 check (qty_daikon_kiri >= 0);

-- ── 野菜：かぼちゃ ──
alter table public.melon_order_requests add column qty_kabocha_kikaku integer not null default 0 check (qty_kabocha_kikaku >= 0);

-- ── 野菜：にんじん ──
alter table public.melon_order_requests add column qty_ninjin_kikaku integer not null default 0 check (qty_ninjin_kikaku >= 0);

-- ── ご連絡方法の種別（インスタ／メールまたは電話） ──
alter table public.melon_order_requests add column contact_type text check (contact_type in ('instagram', 'email_or_tel'));

-- ── 数量チェック制約の再作成（野菜の数量も対象に含める） ──
alter table public.melon_order_requests drop constraint melon_order_requests_qty_check;

alter table public.melon_order_requests add constraint melon_order_requests_qty_check check (
  qty_3l + qty_4l + qty_5l + qty_other
  + qty_arusu_l + qty_arusu_2l + qty_arusu_3l
  + qty_kokabu_kikaku + qty_kokabu_naka
  + qty_daikon_s + qty_daikon_m + qty_daikon_l + qty_daikon_2l + qty_daikon_kiri
  + qty_kabocha_kikaku + qty_ninjin_kikaku > 0
  or onion_kg > 0
);

-- ============================================================
-- 完了！
-- ============================================================
