-- ============================================================
-- 村上農園 メロン予約 - 注文仮受付Noの追加
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- お客様向け注文フォーム（melon_order.html）で送信を確定した時刻から
-- 「YYMMDDHHMM」形式（西暦下2桁+月+日+時+分・JST）の注文仮受付Noを
-- 発行し、melon_order_requests に保存します。
-- 承認後は melon_entries（予約表の行）の備考欄にも自動で追記されるため、
-- 管理者画面（予約表・注文リクエスト一覧）の両方で確認できます。
-- ============================================================

alter table public.melon_order_requests add column if not exists request_no text;

create index if not exists melon_order_requests_request_no_idx
  on public.melon_order_requests (request_no);

-- ============================================================
-- 完了！
-- ============================================================
