-- ============================================================
-- 勤怠打刻の対象メンバーを、タスク管理のスタッフ（profiles）とは
-- 独立した専用マスタで管理できるようにする
-- （パート・社員・技能実習生等、ログインアカウントを持たない人も
-- 　含めて管理できるようにするため）
-- SupabaseのSQL Editorに貼り付けて「Run」を押してください
-- ============================================================

create table public.kintai_staff (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,            -- 打刻画面に表示する名前
  category   text,                     -- 分類（例：インドネシア／カンボジア／日本人）
  status     text,                     -- 在留資格・雇用形態（例：特定技能1号／技能実習生3号／社員／パート）
  sort_order integer not null default 0,
  active     boolean not null default true,  -- false＝退職等で打刻対象から外れたメンバー
  created_at timestamptz not null default now()
);

alter table public.kintai_staff enable row level security;

create policy "ログイン済みユーザーは勤怠メンバーを閲覧できる"
  on public.kintai_staff for select
  using (auth.role() = 'authenticated');

create policy "管理者のみ勤怠メンバーを登録できる"
  on public.kintai_staff for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ勤怠メンバーを更新できる"
  on public.kintai_staff for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "管理者のみ勤怠メンバーを削除できる"
  on public.kintai_staff for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- attendance_records の参照先を profiles → kintai_staff に変更
-- 参照先テーブルが変わるため、既存のテスト打刻データ（あれば）は一旦クリアします
-- （本番運用はまだ開始していない前提。既に実データがある場合は実行前にご相談ください）
truncate table public.attendance_records;
alter table public.attendance_records drop constraint if exists attendance_records_staff_id_fkey;
alter table public.attendance_records add constraint attendance_records_staff_id_fkey
  foreign key (staff_id) references public.kintai_staff(id) on delete cascade;

-- ============================================================
-- 初期データ投入（R8.8時点の従業員一覧）
-- ============================================================
-- 表示名は本人が呼ばれている名前（インドネシア人は名が先頭のためローマ字表記の
-- 最初の単語、カンボジア人は姓が先頭のため2番目の単語、日本人は苗字）を採用
insert into public.kintai_staff (name, category, status, sort_order) values
  ('ハエケル',     'インドネシア', '特定技能2号', 1),
  ('アディ',       'インドネシア', '特定技能1号', 2),
  ('ズルキリフ',    'インドネシア', '特定技能1号', 3),
  ('ムハマド',     'インドネシア', '特定技能1号', 4),
  ('ディアン',     'インドネシア', '特定技能1号', 5),
  ('アンドレ',     'インドネシア', '特定技能1号', 6),
  ('ヤディ',       'インドネシア', '特定技能1号', 7),
  ('ユサック',     'インドネシア', '特定技能1号', 8),
  ('ジャジャン',    'インドネシア', '特定技能1号', 9),
  ('ダニー',       'インドネシア', '特定技能1号', 10),
  ('ロフマニ',     'インドネシア', null, 11),
  ('ソピアン',     'カンボジア', '技能実習生3号', 12),
  ('ソワンモニロット', 'カンボジア', '技能実習生3号', 13),
  ('チャントゥー',   'カンボジア', '技能実習生3号', 14),
  ('チャンニー',    'カンボジア', '技能実習生3号', 15),
  ('ヴィチェカー',   'カンボジア', '技能実習生3号', 16),
  ('ソクチア',     'カンボジア', '特定技能1号', 17),
  ('シーナ',       'カンボジア', '特定技能1号', 18),
  ('上田',         '日本人', '社員', 19),
  ('柳澤',         '日本人', '社員', 20),
  ('朝倉',         '日本人', 'パート', 21),
  ('四方',         '日本人', 'パート', 22),
  ('村井',         '日本人', 'パート', 23),
  ('松陰',         '日本人', '社員', 24);

-- ============================================================
-- 完了！
-- ============================================================
