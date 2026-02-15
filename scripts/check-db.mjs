#!/usr/bin/env node
/**
 * Check Supabase connection and word_groups table.
 * Run: node scripts/check-db.mjs
 * Uses .env: SUPABASE_URL and SUPABASE_KEY (anon) or SUPABASE_SERVICE_ROLE_KEY
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { createClient } from '@supabase/supabase-js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const envPath = path.join(__dirname, '..', '.env')

function loadEnv () {
  try {
    const raw = fs.readFileSync(envPath, 'utf8')
    for (const line of raw.split('\n')) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/)
      if (m) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '').trim()
    }
  } catch (_) {}
}

loadEnv()
const url = process.env.SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY

if (!url || !key) {
  console.error('❌ .env に SUPABASE_URL と SUPABASE_KEY（または SUPABASE_SERVICE_ROLE_KEY）を設定してください。')
  process.exit(1)
}

const supabase = createClient(url, key)
console.log('Checking Supabase...')
console.log('URL:', url.replace(/\/\/.*@/, '//***@'))
console.log('')

const { data, error } = await supabase.from('word_groups').select('id, root_word, root_meaning').order('id')

if (error) {
  console.error('❌ Error:', error.message)
  if (error.code === '42P01') {
    console.error('\n→ word_groups テーブルがありません。Supabase SQL Editor で schema.sql を実行してください。')
  } else if (error.code === 'PGRST301' || error.message.includes('policy')) {
    console.error('\n→ RLS で読み取りが許可されていません。schema.sql のポリシーを確認してください。')
  }
  process.exit(1)
}

console.log('✅ Connection OK. word_groups rows:', data?.length ?? 0)
if (data?.length) {
  data.forEach((r) => console.log('  - id:', r.id, '|', r.root_word, '|', r.root_meaning))
}
console.log('')
console.log('Next: npm run push:word-groups で vocabularies.json を反映できます。')
