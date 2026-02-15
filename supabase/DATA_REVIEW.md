# word_groups データの見直しと充実ガイド

## 1. ID と「単語・例文」の関係

### ID について
- **id** は Supabase が自動で振る連番（1, 2, 3, …）です。
- 「id の数字」と「単語の数」や「例文の数」は**対応していません**。id は「どの行か」を区別するためだけに使われています。
- アプリは `id` で並び順（`.order('id')`）を決めているだけです。**どの語源か**は **root_word** で判断してください。

### どういう行が「1件」か
| カラム | 意味 |
|--------|------|
| **1行 = 1つの同じ語源（root_word）** | 例: `cur / curs` が1行、`put` が別の1行 |
| derivatives | その語源から広がる**派生語リスト**（複数可） |
| examples | **穴埋め用の例文**（`____` に答える問題が複数可） |
| example_sentence_en / jpn | **参考例文**（復習ブロックで表示。1文ずつ） |

- 「今日の単語」で表示される**例文** = その行の **examples** の中身（穴埋めの英文）。
- examples が空の行は、**example_sentence_en / jpn** があれば「例文」としてそれらを表示します。

---

## 2. 揃えておきたいこと（ID と単語・例文の一致）

### 2.1 同じ語源でまとめる
- **1行 = 1つの語源（root_word）** にすること。
- **derivatives** には、その語源から広がる単語だけを入れる（別の語源の単語を混ぜない）。

例（良い）:
- root_word: `port` → derivatives: export, import, transport  
例（悪い）:
- root_word: `config` なのに derivatives に `figure` を入れる（figure は別語源なので別の行にする）。

### 2.2 例文（examples）と派生語（derivatives）を対応させる
- **examples** の各要素は `{ "text": ".... ____ ....", "answer": "単語" }`。日本語訳を表示する場合は **"jpn": "訳文"** を追加（任意）。
- **answer** に入れる単語は、その行の **derivatives** に含まれる単語にすると、今日の単語・穴埋めクイズの両方で「単語と例文が一致」します。

例（良い）:
- derivatives に `cursor` がある → examples に `{"text":"Move the ____ to the end.","answer":"cursor","jpn":"行末にカーソルを移動する。"}` がある。

### 2.3 参考例文（example_sentence_en / jpn）
- なくても動きますが、あると**復習**で「参考例文」として表示されます。
- その行の派生語を使った英文・和訳を1文ずつ入れると、学習が豊かになります。

### 2.4 初心者向け説明（任意）
- **root_explanation_jpn**（カラム）: 語源の説明を日本語で長めに書けます。`/beginner` で「語源の意味」の直後に表示されます。
- **derivatives** の各要素に **explanation_jpn**（キー）を追加できます。例: `{"word":"cursor","meaning":"カーソル","explanation_jpn":"画面上の位置を示す印。キーボードで動かせます。"}`  
  `/beginner` で、その派生語の説明として表示されます（未指定の場合は共通の説明文になります）。

---

## 3. コンテンツを充実させるためにやること

### ステップ1: 語源ごとに1行にまとめる
- [ ] 同じ **root_word** の行が重複していないか確認する（Table Editor で root_word を見て重複を削除 or 1行にまとめる）。
- [ ] 1行に入れる **derivatives** は、すべてその **root_word** の語源から広がる単語だけにする。

### ステップ2: 穴埋め例文（examples）を足す・直す
- [ ] 各行に **examples** を最低1件は入れる（空だと穴埋めクイズに出ない）。
- [ ] 形式: `[{"text":"英文の ____ のところに答える","answer":"単語"}]`。空欄は **____**（アンダースコア4本）。
- [ ] 各 **answer** が、その行の **derivatives** のどれかと一致するようにする。
- [ ] 可能なら、**1つの派生語に1つ以上**、意味が分かる例文を書く（自動の "Use ____ in your code." より、自分で書いた例文の方が学習効果が高い）。

### ステップ3: 参考例文を足す
- [ ] **example_sentence_en**: その語源・派生語を使った英文を1文。
- [ ] **example_sentence_jpn**: 上の英文の日本語訳（任意だがあるとよい）。

### ステップ4: vocabularies.json で増やす場合
- [ ] **vocabularies.json** の `vocabularies` 配列に、**root_word だけ**（または root_word + root_meaning）を書けば、残りのカラムはスクリプトが自動で埋めます。
  - **最小例**: `{ "root_word": "script", "root_meaning": "書く (write)" }`  
    → derivatives は `[]`、examples は `[]`、relevent は true で 1 行が作成されます。
  - **derivatives を書いた場合**: 穴埋め用の examples が自動作成されます（「Use ____ in your code.」形式）。手で **examples** を書けば、その内容がそのまま使われます。
- [ ] `npm run generate:word-groups` で SQL を出し、Supabase に反映。または `npm run push:word-groups` で反映。

---

## 3.5 ○×クイズ用の「×」（仲間ではない）語彙の追加

○×クイズでは「この単語、同じ語源の仲間？」と出題し、**○ 仲間** か **× 仲間ではない** を選ばせます。  
正解が **×** になる出題をするには、**relevent: false** の行が必要です。

### やり方
- **word_groups** に、**relevent = false** の行を追加する。
- その行の **root_word** がクイズに表示される「単語」になる。
- その行は「同じ語源の仲間ではない」ので、正解は **×**。
- **derivatives** と **examples** は空でよい（穴埋め・今日の単語では使わない想定）。

### vocabularies.json で追加する場合
同じ **vocabularies** 配列に、次のように **"relevent": false** のエントリを足します。

```json
{
  "root_word": "apple",
  "root_meaning": "りんご（同じ語源とは無関係の単語）",
  "derivatives": [],
  "relevent": false
}
```

- **root_word**: クイズに表示する名前（単語・語根どちらでも可）。
- **root_meaning**: 説明（「〜とは無関係」などでよい）。
- **derivatives**: 空配列 `[]` でよい。
- **relevent**: 必ず **false**。

複数追加する例: `random`（ランダム）、`error`（エラー）、`button`（ボタン）など、メインの語源グループに含めていない単語を入れると、○×の「×」問題が増えます。

追加後は `npm run generate:word-groups` で SQL を生成するか、`npm run push:word-groups` で DB に反映してください。

---

## 4. 現在の vocabularies.json で気をつける点

- **config**: 「figure out」「figure」は語源が config（形作る）と違うので、別の語源として行を分けた方がよいです。config の行には configure, configuration などだけにすると一致します。
- **struct**: 「instruction」は語源が少し違う場合があります。structure, construct などにそろえると分かりやすいです。
- 自動生成される穴埋めは「Use ____ in your code.」の1パターンだけなので、**手で examples を書く**と、単語と例文の対応がはっきりし、コンテンツも充実します。

---

## 5. まとめ

| やること | 効果 |
|----------|------|
| 1行 = 1語源、derivatives はその語源だけ | 「今日の単語」と穴埋めで単語と意味が一致する |
| examples の answer を derivatives に合わせる | 例文と単語が一致し、穴埋めが正しく動く |
| 各行に examples を最低1件 | 穴埋めクイズにその行が出る |
| example_sentence_en/jpn を書く | 復習の「参考例文」が増える |
| vocabularies.json で examples を手書き | 質の高い例文でコンテンツを増やせる |

ID は「行の通し番号」だけなので、**root_word と derivatives / examples の内容を揃える**ことに集中すると、ID と単語・例文の「ずれ」は解消されます。
