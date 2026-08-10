-- ============================================================
-- 休憩時間をスタッフ（グループ）ごとに設定できるようにする
-- 前回作成した break_settings（全体共通・1行のみ）は使わなくなるため削除
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

drop table if exists public.break_settings;

create table public.staff_break_settings (
  staff_id    uuid primary key references public.profiles(id) on delete cascade,
  am_start    time not null default '10:00',
  am_end      time not null default '10:30',
  lunch_start time not null default '12:00',
  lunch_end   time not null default '13:00',
  pm_start    time not null default '15:00',
  pm_end      time not null default '15:30',
  updated_by  uuid references public.profiles(id),
  updated_at  timestamptz not null default now()
);

alter table public.staff_break_settings enable row level security;

create policy "ログイン済みユーザーは休憩時間を閲覧できる"
  on public.staff_break_settings for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ休憩時間を登録できる"
  on public.staff_break_settings for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ休憩時間を更新できる"
  on public.staff_break_settings for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- 完了！
-- ============================================================
