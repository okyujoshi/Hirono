-- クイズスコア保存用テーブル（SQL Editor で実行）
-- ランキング表示用に email を保存（auth.users はクライアントから参照しない）
create table if not exists quiz_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  score int not null,
  total_questions int not null,
  created_at timestamptz default now()
);

alter table quiz_scores enable row level security;

-- 誰でもランキング閲覧可
create policy "Allow public read quiz_scores"
  on quiz_scores for select using (true);

-- ログイン済みユーザーは自分のスコアのみ挿入可能
create policy "Allow authenticated insert own score"
  on quiz_scores for insert
  with check (auth.uid() = user_id);

-- 必要なら: ユーザーは自分のスコアのみ削除可
create policy "Allow users delete own scores"
  on quiz_scores for delete
  using (auth.uid() = user_id);

-- ランキング用インデックス
create index if not exists quiz_scores_score_desc on quiz_scores(score desc, created_at desc);
