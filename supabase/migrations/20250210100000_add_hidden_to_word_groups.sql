-- 管理画面で「非表示」にした単語を学習・初心者ページに表示しない
-- Supabase SQL Editor で実行

alter table word_groups
  add column if not exists hidden boolean not null default false;

comment on column word_groups.hidden is 'true=非表示（学習・初心者ページに出さない）。管理画面の「非表示」で切り替え。';
