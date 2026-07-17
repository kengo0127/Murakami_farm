-- ============================================================
-- 村上農園 タスク管理アプリ 追加機能マイグレーション（2026-07-17）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   1. task_starts（開始記録）テーブルの再定義（既存環境では存在するはずなので IF NOT EXISTS）
--   2. 開始／完了ボタンの「キャンセル」を可能にするDELETEポリシー追加
--   3. work_reports（自発的な作業報告）テーブルの新規作成
-- ============================================================


-- ============================================================
-- 1. task_starts（開始記録）
-- setup.sql には未反映だったため、ここで定義を補完
-- ============================================================
create table if not exists public.task_starts (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid not null references public.tasks(id) on delete cascade,
  started_by  uuid references public.profiles(id),
  started_at  timestamptz not null default now(),
  unique(task_id)
);

alter table public.task_starts enable row level security;

drop policy if exists "ログイン済みユーザーは開始記録を閲覧できる" on public.task_starts;
create policy "ログイン済みユーザーは開始記録を閲覧できる"
  on public.task_starts for select
  using (auth.role() = 'authenticated');

drop policy if exists "ログイン済みユーザーは開始を記録できる" on public.task_starts;
create policy "ログイン済みユーザーは開始を記録できる"
  on public.task_starts for insert
  with check (auth.role() = 'authenticated');


-- ============================================================
-- 2. キャンセル機能用のDELETEポリシー
--   - 開始の取消：押した本人のみ、かつまだ完了報告されていない場合のみ
--   - 完了の取消：押した本人のみ
-- ============================================================
drop policy if exists "本人は未完了の開始記録を取り消せる" on public.task_starts;
create policy "本人は未完了の開始記録を取り消せる"
  on public.task_starts for delete
  using (
    auth.uid() = started_by
    and not exists (
      select 1 from public.task_completions tc where tc.task_id = task_starts.task_id
    )
  );

drop policy if exists "本人は自分の完了記録を取り消せる" on public.task_completions;
create policy "本人は自分の完了記録を取り消せる"
  on public.task_completions for delete
  using (auth.uid() = completed_by);


-- ============================================================
-- 3. work_reports（自発的な作業報告）
-- スタッフが自主的に行った作業（収穫・整理整頓・除草・在庫確認）の報告
-- ============================================================
create table if not exists public.work_reports (
  id           uuid primary key default gen_random_uuid(),
  date         date not null,
  staff_id     uuid not null references public.profiles(id),
  work_type    text not null check (work_type in ('収穫', '整理整頓', '除草', '在庫確認')),
  quantity     integer check (quantity is null or (quantity between 0 and 99)),
  unit         text check (unit is null or unit in ('kg', '本', '玉')),
  reported_at  timestamptz not null default now()
);

alter table public.work_reports enable row level security;

drop policy if exists "ログイン済みユーザーは自発報告を閲覧できる" on public.work_reports;
create policy "ログイン済みユーザーは自発報告を閲覧できる"
  on public.work_reports for select
  using (auth.role() = 'authenticated');

drop policy if exists "スタッフは自分の自発報告を登録できる" on public.work_reports;
create policy "スタッフは自分の自発報告を登録できる"
  on public.work_reports for insert
  with check (auth.uid() = staff_id);


-- ============================================================
-- 完了！
-- ============================================================
