-- 初心者レッスン用：語源の説明（日本語）を追加
-- Supabase SQL Editor で実行。既存テーブルにカラムを追加します。
-- derivatives の JSON には任意で explanation_jpn を追加可能（スキーマ変更なし）

alter table word_groups
  add column if not exists root_explanation_jpn text;

comment on column word_groups.root_explanation_jpn is '初心者向け：語源の説明（日本語）。長めの解説を書くと /beginner で表示されます。';
