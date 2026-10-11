-- ============================================================
-- インスタ・EC：支払い方法に「振込」を追加・届け先の列を追加（2026-10-11）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- （migration_2026-10-11_ec_custom_items.sql の後に実行してください）
--
-- 内容：
--   1. 支払い方法を「現金／PayPay／振込」の3つから1つ選ぶ方式にするため、振込の列を追加する
--      （現金・PayPayは既存の paid_cash / paid_paypay をそのまま使う。どれか1つだけ true にするのは画面側で制御）
--   2. 発送の届け先（都道府県など）を記録する列を追加する（届け先によって送料が変わるため、その確認用）
-- ============================================================

alter table public.melon_entries add column if not exists paid_transfer boolean not null default false;
alter table public.melon_entries add column if not exists ship_to text;

-- ============================================================
-- 完了！
-- ============================================================
