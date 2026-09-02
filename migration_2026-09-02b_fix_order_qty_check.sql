-- ============================================================
-- お客様向け注文フォームの不具合修正マイグレーション（2026-09-02）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   melon_order_requests の数量チェック制約（1品目以上の注文を必須にする
--   ためのもの）が、マルセイユメロン・玉ねぎのみを対象にしたままで、
--   アールスメロン（qty_arusu_l/2l/3l）が考慮されていなかった。
--   そのため「アールスメロンだけ」を注文しようとすると、この制約に
--   違反してエラーになっていた。制約にアールスメロンの数量も含める。
-- ============================================================

alter table public.melon_order_requests drop constraint melon_order_requests_qty_check;

alter table public.melon_order_requests add constraint melon_order_requests_qty_check check (
  qty_3l + qty_4l + qty_5l + qty_other
  + qty_arusu_l + qty_arusu_2l + qty_arusu_3l > 0
  or onion_kg > 0
);

-- ============================================================
-- 完了！
-- ============================================================
