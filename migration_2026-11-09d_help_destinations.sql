-- ============================================================
-- 勤怠：お手伝い先（外出・帰社）（2026-11-09）
-- migration_2026-11-09c_kintai_clock_in_guard.sql の後に実行してください
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 内容：
--   スタッフの一部は近所のお手伝い先に行くことがある。
--   勤怠入力画面で出勤時に「外出（お手伝い先）」を選ぶと、
--     ・始業時間が決まっているお手伝い先（例：8:00）は、打刻時刻と関係なく始業をその時刻で確定する
--     ・始業時間が決まっていないお手伝い先は、通常どおり打刻時刻から始業を求める（30分切り上げ）
--   外出した人は、次に「帰社」ボタン（帰社時刻を記録）→ 休憩 → 退勤 の順に押す。
--   お手伝い先の一覧は管理画面「勤怠 → お手伝い先の管理」で編集する。
-- ============================================================

create table public.help_destinations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  start_time  time,                      -- 始業時間（null＝決まっていない → 打刻時刻を使う）
  active      boolean not null default true,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

alter table public.help_destinations enable row level security;

create policy "ログイン済みユーザーはお手伝い先を閲覧できる"
  on public.help_destinations for select
  using (auth.role() = 'authenticated');

create policy "管理者はお手伝い先を編集できる"
  on public.help_destinations for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

insert into public.help_destinations (name, start_time, sort_order) values
  ('西農園',             '08:00', 1),
  ('フィールドワークス', '08:00', 2),
  ('本原農園',           '08:00', 3),
  ('三協',               '08:00', 4),
  ('グリーンパートナー', null,    5);

-- 勤怠記録に「お手伝い先」「確定した始業時間」「帰社時刻」を追加
-- （お手伝い先の名前・始業時間はその日の記録にも写して保存し、後で一覧を変更・削除しても過去の記録は変わらないようにする）
alter table public.attendance_records
  add column help_destination_id   uuid references public.help_destinations(id) on delete set null,
  add column help_destination_name text,
  add column fixed_start_time      time,          -- null＝打刻時刻から始業を求める
  add column returned_at           timestamptz;   -- 帰社時刻

-- 出勤時刻の制限（migration_2026-11-09c）に、お手伝い先・帰社の制限を追加（管理者以外）
--   ・お手伝い先の名前・始業時間は、画面から送られた値ではなく、お手伝い先の一覧から決める
--   ・お手伝い先は登録後に変更できない（修正は管理者）。始業時間は遅らせる方向にのみ変更できる（現在時刻まで）
--   ・帰社時刻は「いまの時刻」（前後10分まで）のみ記録できる。取り消し（空に戻す）は可
create or replace function public.guard_attendance_clock_in()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  dest record;
begin
  if auth.uid() is null
     or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.clock_in is not null
       and (new.clock_in < now() - interval '10 minutes' or new.clock_in > now() + interval '10 minutes') then
      raise exception '出勤時刻は現在の時刻でのみ記録できます（修正は管理者に依頼してください）';
    end if;

    new.help_destination_name := null;
    new.fixed_start_time := null;
    new.returned_at := null;
    if new.help_destination_id is not null then
      select name, start_time into dest
      from public.help_destinations
      where id = new.help_destination_id and active;
      if not found then
        raise exception 'お手伝い先が見つかりません';
      end if;
      new.help_destination_name := dest.name;
      new.fixed_start_time := dest.start_time;
    end if;
  else
    if new.clock_in is distinct from old.clock_in then
      raise exception '出勤時刻は管理者のみ変更できます';
    end if;
    if new.help_destination_id is distinct from old.help_destination_id
       or new.help_destination_name is distinct from old.help_destination_name then
      raise exception 'お手伝い先は管理者のみ変更できます';
    end if;
    -- 始業時間は「遅らせる」だけ可（お手伝い先に遅れて着いたときなど）。前倒し・未来の時刻・決まっていない日への設定は不可
    if new.fixed_start_time is distinct from old.fixed_start_time then
      if old.fixed_start_time is null or new.fixed_start_time is null
         or new.fixed_start_time <= old.fixed_start_time
         or ((new.date + new.fixed_start_time) at time zone 'Asia/Tokyo') > now() + interval '10 minutes' then
        raise exception '始業時間は、いまの始業時間より後（現在時刻まで）にのみ変更できます';
      end if;
    end if;
    if new.returned_at is not null and new.returned_at is distinct from old.returned_at
       and (new.returned_at < now() - interval '10 minutes' or new.returned_at > now() + interval '10 minutes') then
      raise exception '帰社時刻は現在の時刻でのみ記録できます（修正は管理者に依頼してください）';
    end if;
  end if;

  return new;
end;
$$;

-- ============================================================
-- 完了！
-- ============================================================
