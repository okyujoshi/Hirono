# Supabase セットアップ（Hirono）

- **データの見直し・充実**: [DATA_REVIEW.md](./DATA_REVIEW.md) — ID と単語・例文の関係、整合性の取り方、コンテンツを増やす手順。

## つまずいたときは（Stuck? Do this）

データベースがうまくいかないときは、次の順で試してください。

1. **接続とテーブルを確認**
   ```bash
   npm run check-db
   ```
   - `.env` に `SUPABASE_URL` と `SUPABASE_KEY`（Dashboard → Settings → API の **anon public**）を書いてあるか確認。
   - 「word_groups テーブルがありません」と出たら → 次のステップへ。

2. **テーブルを作る（まだの場合）**
   - [Supabase Dashboard](https://supabase.com/dashboard) → プロジェクト → **SQL Editor** → **New query**
   - このリポジトリの **supabase/schema.sql** を開き、中身をすべてコピーして貼り付け → **Run**
   - もう一度 `npm run check-db` を実行し、✅ になるか確認。

3. **ローカルからデータを反映できるようにする（SQL Editor で1回だけ）**
   - SQL Editor で **New query**
   - **supabase/allow-word-groups-insert-update.sql** の内容をコピーして貼り付け → **Run**
   - これで anon キーでも insert/update できるようになります（service_role は不要）。

4. **語彙を Supabase に送る**
   - `supabase/vocabularies.json` を編集したあと、ターミナルで:
   ```bash
   npm run push:word-groups
   ```
   - `.env` には `SUPABASE_URL` と `SUPABASE_KEY`（anon）だけでOKです。

まだエラーが出る場合は、`npm run check-db` の表示メッセージをメモしてサポートに伝えると原因を特定しやすいです。

---

## word_groups テーブル（8カラム）

| カラム | 型 | 説明 |
|--------|-----|------|
| id | bigint | 主キー（自動採番） |
| root_word | text | 同じ語源または単語 |
| root_meaning | text | 意味 |
| derivatives | jsonb | 派生語リスト。例: `[{"word":"cursor","meaning":"カーソル"}]` |
| examples | jsonb | 穴埋め問題。例: `[{"text":"Move the ____ to the end.","answer":"cursor"}]` |
| example_sentence_en | text | 参考例文（英語） |
| example_sentence_jpn | text | 参考例文（日本語） |
| relevent | boolean | ○×クイズ用: この単語は同じ語源の仲間か（true=○, false=×） |

## 初回セットアップ

1. [Supabase Dashboard](https://supabase.com/dashboard) → プロジェクト → **SQL Editor** → **New query**
2. **schema.sql** の内容をコピーして貼り付け → **Run**
3. `word_groups` が作成され、サンプル1件が入ります。

## レコードの追加（Table Editor）

1. **Table Editor** → **word_groups** → **Insert row**
2. **root_word**: 同じ語源または単語（例: `cur / curs`）
3. **root_meaning**: 意味（例: `走る、流れる (run, flow)`）
4. **derivatives**: JSON 配列（例: `[{"word":"cursor","meaning":"カーソル"}]`）
5. **examples**: JSON 配列。穴埋めは `____` を空欄に（例: `[{"text":"Move the ____ to the end.","answer":"cursor"}]`）
6. **example_sentence_en** / **example_sentence_jpn**: 参考例文（任意）
7. **relevent**: ○×クイズで「この単語は同じ語源の仲間か？」の正解（true=○、false=×）

学習ページを再読み込みすると反映されます。

## 語彙ファイルから一括生成（8カラムを自動作成）

語彙だけ書いて、残りのカラム（derivatives / examples / 例文など）を自動で埋めたい場合は **vocabularies.json** とスクリプトを使います。

1. **supabase/vocabularies.json** を編集する  
   - `vocabularies` 配列に、次のようなオブジェクトを追加します。  
   - 必須: `root_word`, `root_meaning`  
   - 任意: `derivatives`（`[{ "word": "export", "meaning": "輸出する" }]`）、`example_sentence_en` / `example_sentence_jpn`、`examples`（穴埋めを自分で書く場合）、`relevent`（省略時は true）

2. スクリプトで SQL を生成する  
   ```bash
   npm run generate:word-groups
   ```  
   - 標準出力に `word_groups` 用の INSERT 文が出ます。  
   - `examples` を書いていない場合は、派生語から「Use ____ in your code.」形式の穴埋めが自動で作られます。

3. 生成された SQL を Supabase の **SQL Editor** に貼り付けて **Run** する。

## ローカルで編集して Supabase に反映（SQL Editor を使わない）

**vocabularies.json をローカルで編集し、コマンド1つで DB に反映できます。**

1. **Supabase で insert/update を許可する（初回のみ）**  
   - SQL Editor で **allow-word-groups-insert-update.sql** を実行しておく（「つまずいたときは」の手順3参照）。  
   - これで **anon キー**（`SUPABASE_KEY`）だけで push できます。service_role は不要です。

2. **.env** に `SUPABASE_URL` と `SUPABASE_KEY`（anon public）を書く。

3. **supabase/vocabularies.json** を編集する（語彙の追加・修正）。

4. ターミナルで実行  
   ```bash
   npm run push:word-groups
   ```  
   - 同じ `root_word` がある行は **更新**、ない場合は **新規挿入** されます。

### テーブルをローカルにダウンロードしたい場合

- **Table Editor:** word_groups を開く → 右上の **Export** などで CSV をダウンロード可能です。  
- 手動で編集したあと、その内容を **vocabularies.json** の形式に合わせて追記し、`npm run push:word-groups` で反映できます。
