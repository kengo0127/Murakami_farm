-- ============================================================
-- 休憩時間（AM休憩・昼休憩・PM休憩）を管理者が変更できるようにする
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

-- 常に1行だけを持つ設定テーブル（id=1固定）
create table public.break_settings (
  id          integer primary key default 1 check (id = 1),
  am_start    time not null default '10:00',
  am_end      time not null default '10:30',
  lunch_start time not null default '12:00',
  lunch_end   time not null default '13:00',
  pm_start    time not null default '15:00',
  pm_end      time not null default '15:30',
  updated_by  uuid references public.profiles(id),
  updated_at  timestamptz not null default now()
);

insert into public.break_settings (id) values (1);

alter table public.break_settings enable row level security;

create policy "ログイン済みユーザーは休憩時間を閲覧できる"
  on public.break_settings for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ休憩時間を更新できる"
  on public.break_settings for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- 完了！
-- ============================================================
