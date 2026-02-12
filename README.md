# Nuxt Minimal Starter

Look at the [Nuxt documentation](https://nuxt.com/docs/getting-started/introduction) to learn more.

## Supabase（データベースが読めないとき）

1. **環境変数**  
   ルートに `.env` を作り、次を設定（値は Supabase Dashboard → Settings → API で確認）:
   ```env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_KEY=your-anon-public-key
   ```

2. **開発サーバーを再起動**  
   `.env` を変更したら **必ず** 開発サーバーを止めてから `npm run dev` で再起動する。反映されないときは再起動が足りないことが多い。

3. **テーブル作成**  
   Supabase の SQL Editor で `supabase/schema.sql` を実行し、`word_groups` と `words` を作成する。未作成だと「単語が0件」やエラーになる。

4. **学習ページのエラー表示**  
   `/learn` でエラーが出る場合、画面上にメッセージと「再試行」ボタンが表示される。表示されたエラー内容で原因を切り分けられる。

## Setup

Make sure to install dependencies:

```bash
# npm
npm install

# pnpm
pnpm install

# yarn
yarn install

# bun
bun install
```

## Development Server

Start the development server on `http://localhost:3000`:

```bash
# npm
npm run dev

# pnpm
pnpm dev

# yarn
yarn dev

# bun
bun run dev
```

## Production

Build the application for production:

```bash
# npm
npm run build

# pnpm
pnpm build

# yarn
yarn build

# bun
bun run build
```

Locally preview production build:

```bash
# npm
npm run preview

# pnpm
pnpm preview

# yarn
yarn preview

# bun
bun run preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.
