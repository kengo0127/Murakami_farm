-- ============================================================
-- 村上農園 メロン予約管理 顧客マスタの並び順追加マイグレーション（2026-07-20）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   名前選択リストを、あいうえお順ではなく元のExcel（顧客リスト.xlsx）の
--   B列に記載されている順番で表示できるように、customers に
--   sort_order 列（Excel記載順）を追加する。
--
-- 注意：この後、更新版の seed_customers.sql を実行して
--       既存データの sort_order を埋めてください。
-- ============================================================

alter table public.customers
  add column if not exists sort_order integer not null default 0;

create index if not exists customers_kana_row_sort_order_idx
  on public.customers (kana_row, sort_order);

-- ============================================================
-- 完了！
-- ============================================================
