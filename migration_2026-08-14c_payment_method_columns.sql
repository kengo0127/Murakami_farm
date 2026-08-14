-- ============================================================
-- 村上農園 メロン予約 - 支払い方法（現金・PayPay）列の追加
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- インスタ・EC注文管理表（melon_sheet.html）の「入金」列の横に、
-- 支払い方法を記録するチェック欄「現金支払い」「PayPay支払い」を
-- 追加します。
-- ============================================================

alter table public.melon_entries add column if not exists paid_cash boolean not null default false;
alter table public.melon_entries add column if not exists paid_paypay boolean not null default false;

-- ============================================================
-- 完了！
-- ============================================================
