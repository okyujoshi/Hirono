# Supabase セットアップ（Hirono）

## word_groups テーブル（8カラム）

| カラム | 型 | 説明 |
|--------|-----|------|
| id | bigint | 主キー（自動採番） |
| root_word | text | 語根または単語 |
| root_meaning | text | 意味 |
| derivatives | jsonb | 派生語リスト。例: `[{"word":"cursor","meaning":"カーソル"}]` |
| examples | jsonb | 穴埋め問題。例: `[{"text":"Move the ____ to the end.","answer":"cursor"}]` |
| example_sentence_en | text | 参考例文（英語） |
| example_sentence_jpn | text | 参考例文（日本語） |
| relevent | boolean | ○×クイズ用: この単語は語根の仲間か（true=○, false=×） |

## 初回セットアップ

1. [Supabase Dashboard](https://supabase.com/dashboard) → プロジェクト → **SQL Editor** → **New query**
2. **schema.sql** の内容をコピーして貼り付け → **Run**
3. `word_groups` が作成され、サンプル1件が入ります。

## レコードの追加（Table Editor）

1. **Table Editor** → **word_groups** → **Insert row**
2. **root_word**: 語根または単語（例: `cur / curs`）
3. **root_meaning**: 意味（例: `走る、流れる (run, flow)`）
4. **derivatives**: JSON 配列（例: `[{"word":"cursor","meaning":"カーソル"}]`）
5. **examples**: JSON 配列。穴埋めは `____` を空欄に（例: `[{"text":"Move the ____ to the end.","answer":"cursor"}]`）
6. **example_sentence_en** / **example_sentence_jpn**: 参考例文（任意）
7. **relevent**: ○×クイズで「この単語は語根の仲間か？」の正解（true=○、false=×）

学習ページを再読み込みすると反映されます。
