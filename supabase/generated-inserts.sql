-- ★ Supabase SQL Editor に貼り付けて Run してください（vocabularies.json ではなくこの SQL を貼ること）
-- 同じ root_word がいる場合はスキップするので、何度実行しても重複エラーになりません。

insert into word_groups (root_word, root_meaning, derivatives, examples, example_sentence_en, example_sentence_jpn, relevent)
select 'config', '共に＋形作る', '[{"word":"configuration","meaning":"設定"},{"word":"configurable","meaning":"設定可能な"},{"word":"figure out","meaning":"考え出す、解決する"},{"word":"figure","meaning":"図、図形"}]'::jsonb, '[{"text":"Use ____ in your code.","answer":"configuration"},{"text":"Use ____ in your code.","answer":"configurable"},{"text":"Use ____ in your code.","answer":"figure out"},{"text":"Use ____ in your code.","answer":"figure"}]'::jsonb, null, null, true
where not exists (select 1 from word_groups where root_word = 'config');

insert into word_groups (root_word, root_meaning, derivatives, examples, example_sentence_en, example_sentence_jpn, relevent)
select 'port', '運ぶ (carry)', '[{"word":"export","meaning":"輸出する、エクスポート"},{"word":"import","meaning":"輸入する、インポート"},{"word":"transport","meaning":"運送する"}]'::jsonb, '[{"text":"Use ____ in your code.","answer":"export"},{"text":"Use ____ in your code.","answer":"import"},{"text":"Use ____ in your code.","answer":"transport"}]'::jsonb, 'Export the data to a CSV file.', 'データをCSVファイルにエクスポートする。', true
where not exists (select 1 from word_groups where root_word = 'port');

insert into word_groups (root_word, root_meaning, derivatives, examples, example_sentence_en, example_sentence_jpn, relevent)
select 'struct', '積み上げる、建てる (build)', '[{"word":"structure","meaning":"構造"},{"word":"construct","meaning":"建設する、構築する"},{"word":"instruction","meaning":"指示、命令"}]'::jsonb, '[{"text":"Use ____ in your code.","answer":"structure"},{"text":"Use ____ in your code.","answer":"construct"},{"text":"Use ____ in your code.","answer":"instruction"}]'::jsonb, null, null, true
where not exists (select 1 from word_groups where root_word = 'struct');
