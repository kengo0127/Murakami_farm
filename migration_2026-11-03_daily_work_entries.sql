-- ============================================================
-- スタッフの「今日の作業報告（日報）」マイグレーション（2026-11-03）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   スタッフ画面の時間割（7:00〜20:00、Outlookのスケジューラ風）に入力した作業を
--   1作業＝1行で保存するテーブル。
--   スタッフは共用アカウントでログインしているため、だれの作業かは
--   社員リスト（kintai_staff）から選んだ名前（staff_id / staff_name）で区別する。
-- ============================================================

create table public.daily_work_entries (
  id          uuid primary key default gen_random_uuid(),
  work_date   date not null,
  staff_id    uuid references public.kintai_staff(id) on delete set null,
  staff_name  text not null,             -- 社員リストの呼び名（退職後も残るよう名前でも保存）
  crop        text not null,             -- 作物（メロン／スイカ／こかぶ／大根／その他）
  task_name   text not null,             -- 作業（リストから選択 or 自由記入）
  start_time  time not null,
  end_time    time not null,
  created_by  uuid default auth.uid(),   -- ログインしていたアカウント（共用アカウント）
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint daily_work_entries_time_check check (end_time > start_time)
);

create index daily_work_entries_date_staff_idx
  on public.daily_work_entries (work_date, staff_name);

alter table public.daily_work_entries enable row level security;

create policy "ログイン済みユーザーは日報を閲覧できる"
  on public.daily_work_entries for select
  using (auth.role() = 'authenticated');

create policy "スタッフと管理者は日報を登録できる"
  on public.daily_work_entries for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('staff', 'admin'))
  );

create policy "スタッフと管理者は日報を更新できる"
  on public.daily_work_entries for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('staff', 'admin'))
  );

create policy "スタッフと管理者は日報を削除できる"
  on public.daily_work_entries for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('staff', 'admin'))
  );

-- ============================================================
-- 完了！
-- ============================================================
