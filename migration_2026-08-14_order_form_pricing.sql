-- ============================================================
-- 村上農園 メロン予約 - お客様向け注文フォームでの単価・合計金額表示
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- お客様向け注文フォーム（melon_order.html）に単価・合計金額（目安）を
-- 表示するため、未ログインのお客様（anon）にも下記2テーブルの閲覧を
-- 許可します。
--   - melon_sheets：年月の存在確認用（id, year, month など）
--   - melon_price_periods：単価情報そのもの
-- お客様のお名前・注文明細などのプライベートな情報は melon_entries に
-- あり、今回の変更では公開されません（melon_entries のポリシーは変更なし）。
-- ============================================================

alter table public.melon_sheets enable row level security;
alter table public.melon_price_periods enable row level security;

create policy "誰でも月次シートの年月を閲覧できる" on public.melon_sheets for select
  to anon, authenticated
  using (true);

create policy "誰でも単価情報を閲覧できる" on public.melon_price_periods for select
  to anon, authenticated
  using (true);

-- ============================================================
-- 完了！
-- これで melon_order.html が、ご来店希望日の属する月の予約表に
-- 設定されている単価（一時的な割引期間を含む）を参照できるようになります。
-- まだその月の予約表が作成されていない場合は、規定単価（js/melon-common.js
-- の DEFAULT_PRICES）が表示されます。
-- ============================================================
