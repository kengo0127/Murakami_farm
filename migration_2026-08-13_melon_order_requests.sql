-- ============================================================
-- 村上農園 メロン予約 - お客様からの注文リクエスト機能
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

-- ============================================================
-- 1. melon_order_requests（お客様からの注文リクエスト）
-- ログイン不要のお客様向けフォームから送信される「申請」。
-- 社員が内容を確認し、承認して初めて melon_entries（正式な予約表の行）に反映される。
-- 金額に関わる単価カラムは持たせない（承認時にそのシートの適用単価を自動で使う）。
-- ============================================================
create table public.melon_order_requests (
  id                uuid primary key default gen_random_uuid(),

  customer_name     text not null,               -- お名前（自由入力）
  contact           text,                         -- 連絡先（電話番号・インスタのユーザー名など、任意）

  entry_date        date not null,                -- お届け希望日

  qty_3l            integer not null default 0 check (qty_3l >= 0),
  qty_4l            integer not null default 0 check (qty_4l >= 0),
  qty_5l            integer not null default 0 check (qty_5l >= 0),
  qty_other         integer not null default 0 check (qty_other >= 0),
  other_label       text,                         -- 「その他」の内容メモ（任意）

  onion_kg          numeric(6,2) not null default 0 check (onion_kg >= 0),

  note              text,                         -- お客様からの備考

  status            text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by       uuid references public.profiles(id),
  reviewed_at       timestamptz,
  melon_entry_id    uuid references public.melon_entries(id) on delete set null, -- 承認後に作成された予約行

  created_at        timestamptz not null default now(),

  constraint melon_order_requests_qty_check check (qty_3l + qty_4l + qty_5l + qty_other > 0 or onion_kg > 0)
);

create index on public.melon_order_requests (status);

-- ============================================================
-- 2. RLS
--    - 送信（insert）：ログイン不要の誰でも可能（お客様向けフォーム用）
--    - 閲覧・更新・削除：管理者のみ
-- ============================================================
alter table public.melon_order_requests enable row level security;

create policy "誰でも注文リクエストを送信できる" on public.melon_order_requests for insert
  to anon, authenticated
  with check (status = 'pending' and reviewed_by is null and reviewed_at is null and melon_entry_id is null);

create policy "管理者はリクエストを閲覧できる" on public.melon_order_requests for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者はリクエストを更新できる" on public.melon_order_requests for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "管理者はリクエストを削除できる" on public.melon_order_requests for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- ============================================================
-- 完了！
-- 次のステップ：melon_order.html（お客様向けフォーム）を
-- 好きな場所で公開し、URLをインスタのDM・固定投稿などで案内してください。
-- ============================================================
