-- ============================================================
-- 村上農園 タスク管理アプリ Supabase セットアップSQL
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================


-- ============================================================
-- 1. profiles（ユーザープロフィール）
-- Supabase Authでログインしたユーザーの追加情報を管理
-- ============================================================
create table public.profiles (
  id        uuid primary key references auth.users(id) on delete cascade,
  name      text not null,
  role      text not null default 'staff' check (role in ('staff', 'admin')),
  created_at timestamptz not null default now()
);

-- 新規ユーザー登録時にprofilesを自動作成するトリガー
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'staff')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ============================================================
-- 2. tasks（タスク）
-- 管理者が毎朝登録する1日のタスク
-- ============================================================
create table public.tasks (
  id               uuid primary key default gen_random_uuid(),
  date             date not null,
  crop             text not null,
  task_name        text not null,
  scheduled_start  time not null,
  scheduled_end    time not null,
  note             text,
  created_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now()
);


-- ============================================================
-- 3. task_assignments（タスク担当割り当て）
-- タスクと担当スタッフの多対多（1タスクに複数スタッフ）
-- ============================================================
create table public.task_assignments (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks(id) on delete cascade,
  staff_id   uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(task_id, staff_id)  -- 同じ組み合わせの重複を防ぐ
);


-- ============================================================
-- 4. task_completions（完了記録）
-- 完了ボタンが押されたときの記録
-- ============================================================
create table public.task_completions (
  id               uuid primary key default gen_random_uuid(),
  task_id          uuid not null references public.tasks(id) on delete cascade,
  completed_by     uuid references public.profiles(id),
  completed_at     timestamptz not null default now(),
  duration_minutes integer,  -- 予定開始時刻からの経過時間（分）
  note             text,
  unique(task_id)  -- 1タスクにつき完了記録は1件のみ
);


-- ============================================================
-- 5. RLS（Row Level Security）ポリシー設定
-- ログインしたユーザーだけがデータにアクセスできるようにする
-- ============================================================

-- profiles
alter table public.profiles enable row level security;

create policy "自分のプロフィールは誰でも読める"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "自分のプロフィールは自分だけ更新できる"
  on public.profiles for update
  using (auth.uid() = id);


-- tasks
alter table public.tasks enable row level security;

create policy "ログイン済みユーザーはタスクを閲覧できる"
  on public.tasks for select
  using (auth.role() = 'authenticated');

create policy "管理者のみタスクを作成できる"
  on public.tasks for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみタスクを更新できる"
  on public.tasks for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみタスクを削除できる"
  on public.tasks for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );


-- task_assignments
alter table public.task_assignments enable row level security;

create policy "ログイン済みユーザーは担当割り当てを閲覧できる"
  on public.task_assignments for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ担当を割り当てできる"
  on public.task_assignments for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ担当割り当てを削除できる"
  on public.task_assignments for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );


-- task_completions
alter table public.task_completions enable row level security;

create policy "ログイン済みユーザーは完了記録を閲覧できる"
  on public.task_completions for select
  using (auth.role() = 'authenticated');

create policy "ログイン済みユーザーは完了を記録できる"
  on public.task_completions for insert
  with check (auth.role() = 'authenticated');


-- ============================================================
-- 完了！
-- 次のステップ：
--   1. Supabase Authentication でスタッフ・管理者アカウントを作成
--   2. Project Settings → API から URL と anon key を取得
-- ============================================================
