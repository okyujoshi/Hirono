# Supabase セットアップ

## Table Editor と SQL Editor の使い分け

| やりたいこと | おすすめ |
|-------------|----------|
| 1〜2件だけ追加・修正 | **Table Editor** — 画面でクリックして編集するだけで簡単 |
| 同じ形式でたくさん追加したい | **SQL Editor** — テンプレートをコピーして値を変えて実行すると速い |
| 例文を一括で入れたい | **SQL Editor** — `update words set example_sentence_en = '...' where en = 'cursor';` のように書ける |
| 語根グループごとに単語をまとめて投入 | **SQL Editor** — **insert_words_examples.sql** のテンプレートを参照 |

SQL で追加・更新した内容も、Vue アプリは **学習ページを再読み込み** すればそのまま反映されます。**insert_words_examples.sql** に、語根の追加・単語の追加・例文の更新のサンプルをまとめてあります。

---

## 認証（メール・パスワード）を有効にする

1. [Supabase Dashboard](https://supabase.com/dashboard) → プロジェクト → **Authentication** → **Providers**
2. **Email** を有効にする（デフォルトで有効）
3. 必要に応じて **Confirm email** をオフにすると、確認メールなしで即ログインできます

---

## 1. 初回セットアップ（テーブル作成）

1. [Supabase Dashboard](https://supabase.com/dashboard) でプロジェクトを開く
2. 左メニュー **SQL Editor** → **New query**
3. このフォルダの **schema.sql** の内容をすべてコピーして貼り付け → **Run**
4. これで `word_groups` と `words` テーブルができ、既存の語根・単語が入ります

## 2. 新しい語根グループを追加

1. **Table Editor** → **word_groups** を開く
2. **Insert row** で行を追加：
   - **root**: 例 `port`
   - **meaning**: 例 `運ぶ (carry)`
   - **sort_order**: 表示順（数字。大きいほど下に表示）

## 3. 単語を追加

1. **Table Editor** → **words** を開く
2. **Insert row** で行を追加：
   - **group_id**: 上で作った語根グループの **id**（word_groups の UUID をコピー）
   - **en**: 英単語（例 `export`）
   - **jp**: 日本語の意味（例 `輸出する、エクスポート`）
   - **note**: 語源メモ（任意、例 `外に運ぶ`）
   - **sort_order**: そのグループ内の表示順（数字）

## 4. 既存グループに単語を足すだけの場合

- **words** テーブルで **Insert row**
- **group_id** に、単語を入れたい語根グループの **id** を指定（word_groups で確認）
- **en**, **jp**, **note**, **sort_order** を入力

アプリを再読み込みすると、Supabase から取得した最新の単語が表示されます。

---

## 5. 単語に例文を追加（コンテキスト）

1. **SQL Editor** で **add_example_sentences.sql** を一度だけ実行 → `words` に `example_sentence_en` と `example_sentence_jp` カラムが追加されます。
2. **Table Editor** で編集する場合: **words** を開き、該当行の **example_sentence_en** / **example_sentence_jp** を入力して保存。
3. **SQL Editor** で編集する場合: **insert_words_examples.sql** の「3. 単語に例文を追加」を参考に、例えば  
   `update words set example_sentence_en = 'Move the cursor to the end.', example_sentence_jp = 'カーソルを行末に移動する。' where en = 'cursor';`  
   のように実行。
4. 学習ページを再読み込みすると、その単語の下に「例: 〜」として表示されます。

---

## 6. SQL Editor で単語・例文を追加（テンプレート）

**insert_words_examples.sql** に、次のようなサンプルを入れています。SQL Editor で開いてコピーし、値を書き換えて Run すると、Table Editor を使わずに追加できます。

- 新しい語根グループの追加（`insert into word_groups ...`）
- 単語の追加（`group_id` は `select id from word_groups where root = 'port'` で取得できるので UUID をコピー不要）
- 既存単語への例文の追加（`update words set example_sentence_en = ..., example_sentence_jp = ... where en = 'cursor'`）
- 単語＋例文の一括追加（`insert into words ... select ... cross join lateral (values ...)`）

実行後、Vue の学習ページを再読み込みすれば反映されます。

---

## 7. 穴埋めクイズ（fill_blanks JSONB）

1. **SQL Editor** で **add_fill_blanks.sql** を実行 → `words` に **fill_blanks**（JSONB）カラムが追加され、サンプルデータが入ります。
2. **Table Editor** で編集する場合:
   - **words** を開く → 該当する単語の行の **fill_blanks** をクリック
   - 次の形式の JSON を入力（正解はその単語の **en** の値になります）:
   ```json
   [{"sentenceEn": "Move the ___ to the end.", "sentenceJp": "___を行末に移動する。"}]
   ```
   - 複数問ある場合は配列にオブジェクトを追加: `[{"sentenceEn":"...","sentenceJp":"..."},{"sentenceEn":"...","sentenceJp":"..."}]`
   - 空欄は **___**（アンダースコア3つ）で表します。
3. 学習ページの「穴埋めクイズ」セクションを再読み込みすると反映されます。

---

## クイズスコア・ランキング用テーブル

1. **SQL Editor** → **New query**
2. **quiz_scores.sql** の内容をコピーして貼り付け → **Run**
3. これでログインユーザーのスコアが保存され、ランキングページに表示されます
