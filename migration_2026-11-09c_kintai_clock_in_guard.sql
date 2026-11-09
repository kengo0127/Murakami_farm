-- ============================================================
-- 勤怠：出勤時刻をさかのぼって記録できないようにする（2026-11-09）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
--
-- 背景：
--   勤怠入力画面（kintai.html）の「出勤時間を選択する」で過去の時刻を選べたため、
--   始業を前倒しして実際より長く働いたことにできてしまった。
--   画面からはボタンを外したが、画面を通さない操作でも防げるよう、データベース側でも制限する。
--
-- 内容（管理者以外）：
--   ・出勤の登録は「いまの時刻」（端末の時計のずれを見込んで前後10分まで）のみ
--   ・登録済みの出勤時刻は変更できない（押し忘れ・修正は管理画面の勤怠から管理者が行う）
--   管理者と、サーバー側の処理（Edge Function などログインユーザーがいないもの）は制限しない
-- ============================================================

create or replace function public.guard_attendance_clock_in()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
  elsif new.clock_in is distinct from old.clock_in then
    raise exception '出勤時刻は管理者のみ変更できます';
  end if;

  return new;
end;
$$;

drop trigger if exists attendance_records_guard_clock_in on public.attendance_records;

create trigger attendance_records_guard_clock_in
  before insert or update on public.attendance_records
  for each row execute function public.guard_attendance_clock_in();

-- ============================================================
-- 完了！
-- ============================================================
