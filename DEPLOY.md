# Vercel デプロイ手順（MedTruth と同様）

## 1. Vercel にプロジェクトを追加

1. [Vercel](https://vercel.com) にログイン
2. **Add New** → **Project**
3. **Import Git Repository** で `okyujoshi/Hirono`（または該当リポジトリ）を選択
4. **Framework Preset**: Nuxt.js が自動検出されます
5. **Root Directory**: そのまま（`./`）
6. **Build Command**: `nuxt build`（デフォルト）
7. **Output Directory**: `.output`（Nuxt が自動設定）
8. **Install Command**: `npm install`（デフォルト）

## 2. 環境変数

**Project Settings → Environment Variables** で以下を設定してください。

| 変数名 | 説明 | 必須 |
|--------|------|:----:|
| `SUPABASE_URL` | Supabase プロジェクト URL（Dashboard → Settings → API） | ✅ |
| `SUPABASE_KEY` | Supabase **anon (public)** key | ✅ |
| `NUXT_PUBLIC_ADMIN_EMAIL` | 管理画面を開けるメール（任意。未設定時は hutz@nifty.com） | 任意 |

**重要**: 環境変数を追加・変更したら **Redeploy** が必要です。

## 3. Supabase の設定

Supabase Dashboard → **Authentication → URL Configuration** で以下を追加：

- **Site URL**: `https://<あなたのプロジェクト>.vercel.app`（デプロイ後の URL）
- **Redirect URLs**: `https://<あなたのプロジェクト>.vercel.app/**`

例: プロジェクト名が `hirono` の場合  
- Site URL: `https://hirono.vercel.app`  
- Redirect URLs: `https://hirono.vercel.app/**`

## 4. デプロイ

- **Deploy** をクリックして初回デプロイ
- 以降は `main` または設定したブランチへ push すると自動デプロイされます（Git 連携時）

## 5. デプロイ後

1. 環境変数が正しく設定されているか確認
2. 必要なら Vercel の **Deployments** で **Redeploy** を実行
3. ブラウザの開発者ツール（F12）→ Console でエラーを確認
4. ログイン・新規登録が動くか確認（Supabase Auth の URL 設定を忘れずに）
