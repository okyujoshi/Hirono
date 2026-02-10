-- Run this in Supabase: SQL Editor → New query → Paste → Run
-- 語根グループ（例: cur/curs, put, script）
create table if not exists word_groups (
  id uuid primary key default gen_random_uuid(),
  root text not null,
  meaning text not null,
  sort_order int not null default 0,
  created_at timestamptz default now()
);

-- 単語（各グループに属する）
create table if not exists words (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references word_groups(id) on delete cascade,
  en text not null,
  jp text not null,
  note text,
  sort_order int not null default 0,
  created_at timestamptz default now()
);

-- 誰でも読めるように（RLS）
alter table word_groups enable row level security;
alter table words enable row level security;

create policy "Allow public read word_groups"
  on word_groups for select using (true);

create policy "Allow public read words"
  on words for select using (true);

-- 既存データを入れる（初回のみ：グループが空のときだけ）
insert into word_groups (root, meaning, sort_order)
select * from (values
  ('cur / curs', '走る、流れる (run, flow)', 1),
  ('put', '考える (think)', 2),
  ('script', '書く (write)', 3)
) as v(root, meaning, sort_order)
where not exists (select 1 from word_groups limit 1);

-- 単語を追加（同じ en が同じグループにいなければ挿入）
insert into words (group_id, en, jp, note, sort_order)
select g.id, v.en, v.jp, v.note, v.sort_order
from word_groups g
cross join lateral (values
  ('cursor', 'カーソル（画面上の位置を示す印）', '流れていくもの → 現在位置', 1),
  ('current', '現在の、電流、流れ', '今流れているもの', 2),
  ('occur', '起こる、発生する', '流れ向かう → 何かが起きる', 3),
  ('recur', '再発する、繰り返す', '再び流れる', 4),
  ('concurrent', '同時の、並行の', '一緒に流れる → 並行処理', 5)
) as v(en, jp, note, sort_order)
where g.root = 'cur / curs'
and not exists (select 1 from words w where w.group_id = g.id and w.en = v.en);

insert into words (group_id, en, jp, note, sort_order)
select g.id, v.en, v.jp, v.note, v.sort_order
from word_groups g
cross join lateral (values
  ('compute', '計算する', '共に考える → 計算', 1),
  ('computer', 'コンピュータ', '計算する機械', 2),
  ('reputation', '評判、名声', '繰り返し考えられること', 3)
) as v(en, jp, note, sort_order)
where g.root = 'put'
and not exists (select 1 from words w where w.group_id = g.id and w.en = v.en);

insert into words (group_id, en, jp, note, sort_order)
select g.id, v.en, v.jp, v.note, v.sort_order
from word_groups g
cross join lateral (values
  ('script', 'スクリプト、台本', '書かれたもの', 1),
  ('description', '記述、説明', '下に書く → 描写', 2),
  ('prescription', '処方、指示', '前に書く → 処方箋', 3)
) as v(en, jp, note, sort_order)
where g.root = 'script'
and not exists (select 1 from words w where w.group_id = g.id and w.en = v.en);
