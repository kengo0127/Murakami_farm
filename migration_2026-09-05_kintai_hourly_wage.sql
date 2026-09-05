-- ============================================================
-- 勤怠メンバーの時給管理 マイグレーション（2026-09-05）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   資格・雇用形態が「社員」以外のメンバー（月給制ではない、時給制の
--   メンバー）について、時給を記録できるようにする。将来の賃上げに
--   備え、「開始日」ごとに時給を複数登録できる履歴形式にする
--   （ある日付に適用される時給は、その日付以前で最も新しい開始日の
--   　レコードを使う。melon_price_periodsと同様の考え方）。
-- ============================================================

create table public.kintai_hourly_wages (
  id         uuid primary key default gen_random_uuid(),
  staff_id   uuid not null references public.kintai_staff(id) on delete cascade,
  wage       integer not null check (wage >= 0),
  start_date date not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(staff_id, start_date)
);

alter table public.kintai_hourly_wages enable row level security;

create policy "ログイン済みユーザーは時給を閲覧できる"
  on public.kintai_hourly_wages for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ時給を登録できる"
  on public.kintai_hourly_wages for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ時給を更新できる"
  on public.kintai_hourly_wages for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ時給を削除できる"
  on public.kintai_hourly_wages for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- 初期データ：「社員」以外の全メンバーに時給1,112円を設定
-- （開始日は2026-08-01。運用開始当初から遡って有効になるよう
-- 　十分に古い日付にしている）
-- ============================================================
insert into public.kintai_hourly_wages (staff_id, wage, start_date)
select id, 1112, '2026-08-01'
from public.kintai_staff
where status is distinct from '社員';

-- ============================================================
-- 完了！
-- ============================================================
