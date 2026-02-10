-- 単語に例文を追加するカラム（SQL Editor で実行）
-- 実行後、Table Editor の words で example_sentence_en / example_sentence_jp を編集できます

alter table words
  add column if not exists example_sentence_en text,
  add column if not exists example_sentence_jp text;

-- コメント（任意）
comment on column words.example_sentence_en is '例文（英語）';
comment on column words.example_sentence_jp is '例文の日本語訳';
