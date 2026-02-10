-- 穴埋めクイズ用の JSONB カラムを words に追加（SQL Editor で実行）
-- 形式: [ {"sentenceEn": "英文（___が空欄）", "sentenceJp": "日本語（___が空欄）"}, ... ]
-- 正解はその単語の en カラムの値

alter table words
  add column if not exists fill_blanks jsonb default '[]';

comment on column words.fill_blanks is '穴埋めクイズの例文。例: [{"sentenceEn":"Move the ___ to the end.","sentenceJp":"___を行末に移動する。"}]';

-- サンプルデータ（cursor, current に1件ずつ入れる）
update words set fill_blanks = '[
  {"sentenceEn": "Move the ___ to the end of the line.", "sentenceJp": "___を行末に移動する。"}
]'::jsonb where en = 'cursor';

update words set fill_blanks = '[
  {"sentenceEn": "The ___ version supports dark mode.", "sentenceJp": "___のバージョンはダークモードに対応している。"}
]'::jsonb where en = 'current';

update words set fill_blanks = '[
  {"sentenceEn": "Errors may ___ when the file is missing.", "sentenceJp": "ファイルがないとエラーが___することがある。"}
]'::jsonb where en = 'occur';

update words set fill_blanks = '[
  {"sentenceEn": "___ the total and return the result.", "sentenceJp": "合計を___して結果を返す。"}
]'::jsonb where en = 'compute';

update words set fill_blanks = '[
  {"sentenceEn": "Run the ___ from the project root.", "sentenceJp": "プロジェクトのルートから___を実行する。"}
]'::jsonb where en = 'script';
