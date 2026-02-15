-- 一度だけ実行: word_groups に insert / update / delete を許可する（anon キーで管理UIから操作できるようにする）
-- Supabase SQL Editor に貼り付けて Run。
-- ※ 本番で一般公開する場合は、認証ユーザーのみに制限することを推奨します。

drop policy if exists "Allow public insert word_groups" on word_groups;
drop policy if exists "Allow public update word_groups" on word_groups;
drop policy if exists "Allow public delete word_groups" on word_groups;

create policy "Allow public insert word_groups"
  on word_groups for insert with check (true);

create policy "Allow public update word_groups"
  on word_groups for update using (true);

create policy "Allow public delete word_groups"
  on word_groups for delete using (true);
