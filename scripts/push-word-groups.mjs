#!/usr/bin/env node
/**
 * Push supabase/vocabularies.json to Supabase word_groups table.
 * - Same root_word already exists → update that row.
 * - New root_word → insert.
 * Requires .env with SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
 * (Dashboard → Settings → API → service_role secret). Do not commit the key.
 *
 * Run: node scripts/push-word-groups.mjs
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { createClient } from '@supabase/supabase-js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.join(__dirname, '..')
const vocabPath = path.join(root, 'supabase', 'vocabularies.json')
const envPath = path.join(root, '.env')

function loadEnv () {
  try {
    const raw = fs.readFileSync(envPath, 'utf8')
    for (const line of raw.split('\n')) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/)
      if (m) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '').trim()
    }
  } catch (_) {}
}

function defaultExamples (derivatives) {
  if (!derivatives?.length) return []
  return derivatives.map(({ word }) => ({ text: 'Use ____ in your code.', answer: word }))
}

function buildRow (v) {
  const derivatives = Array.isArray(v.derivatives) ? v.derivatives : []
  const examples = Array.isArray(v.examples) && v.examples.length ? v.examples : defaultExamples(derivatives)
  return {
    root_word: String(v.root_word ?? ''),
    root_meaning: String(v.root_meaning ?? ''),
    root_explanation_jpn: v.root_explanation_jpn != null ? String(v.root_explanation_jpn) : null,
    derivatives,
    examples,
    example_sentence_en: v.example_sentence_en != null ? String(v.example_sentence_en) : null,
    example_sentence_jpn: v.example_sentence_jpn != null ? String(v.example_sentence_jpn) : null,
    relevent: v.relevent !== false
  }
}

loadEnv()
const url = process.env.SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY
if (!url || !key) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env')
  console.error('Get service_role from: Dashboard → Settings → API → service_role (secret). Do not commit it.')
  process.exit(1)
}

const supabase = createClient(url, key)
const raw = fs.readFileSync(vocabPath, 'utf8')
const data = JSON.parse(raw)
const list = data.vocabularies || data
if (!Array.isArray(list) || !list.length) {
  console.error('No "vocabularies" array in', vocabPath)
  process.exit(1)
}

let ok = 0
let err = 0
for (const v of list) {
  const row = buildRow(v)
  if (!row.root_word?.trim()) {
    console.error('Skipping entry with empty root_word:', v)
    continue
  }
  const { data: existing } = await supabase.from('word_groups').select('id').eq('root_word', row.root_word).maybeSingle()
  if (existing) {
    const { error } = await supabase.from('word_groups').update(row).eq('id', existing.id)
    if (error) {
      console.error('Update failed for', row.root_word, error.message)
      err++
    } else {
      console.log('Updated:', row.root_word)
      ok++
    }
  } else {
    const { error } = await supabase.from('word_groups').insert(row)
    if (error) {
      console.error('Insert failed for', row.root_word, error.message)
      err++
    } else {
      console.log('Inserted:', row.root_word)
      ok++
    }
  }
}
console.log('Done.', ok, 'ok', err, 'errors')
