#!/usr/bin/env node
/**
 * Reads supabase/vocabularies.json and prints SQL INSERT statements
 * for word_groups (8 columns). Run: node scripts/generate-word-groups.mjs
 * Then paste the output into Supabase SQL Editor and run.
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const vocabPath = path.join(__dirname, '..', 'supabase', 'vocabularies.json')

function escapeSql (s) {
  if (s == null || s === '') return null
  return String(s).replace(/'/g, "''")
}

function jsonToSql (obj) {
  return escapeSql(JSON.stringify(obj))
}

/**
 * Build example fill-in-blank items from derivatives when not provided.
 * Uses simple templates so every derivative has at least one example.
 */
function defaultExamples (derivatives) {
  if (!derivatives?.length) return []
  return derivatives.map(({ word }) => ({
    text: `Use ____ in your code.`,
    answer: word
  }))
}

const raw = fs.readFileSync(vocabPath, 'utf8')
const data = JSON.parse(raw)
const list = data.vocabularies || data

if (!Array.isArray(list) || !list.length) {
  console.error('No "vocabularies" array found in', vocabPath)
  process.exit(1)
}

const inserts = []
for (const v of list) {
  const rawWord = v.root_word != null ? String(v.root_word).trim() : ''
  if (!rawWord) {
    console.error('Skipping entry with empty root_word:', v)
    continue
  }
  const root_word = escapeSql(rawWord)
  const root_meaning = escapeSql(v.root_meaning ?? '')
  const derivatives = Array.isArray(v.derivatives) ? v.derivatives : []
  const examples = Array.isArray(v.examples) && v.examples.length
    ? v.examples
    : defaultExamples(derivatives)
  const example_sentence_en = v.example_sentence_en != null ? escapeSql(v.example_sentence_en) : null
  const example_sentence_jpn = v.example_sentence_jpn != null ? escapeSql(v.example_sentence_jpn) : null
  const relevent = v.relevent !== false

  const derivativesJson = jsonToSql(derivatives)
  const examplesJson = jsonToSql(examples)

  const enVal = example_sentence_en != null ? `'${example_sentence_en}'` : 'null'
  const jpnVal = example_sentence_jpn != null ? `'${example_sentence_jpn}'` : 'null'

  inserts.push(
    `insert into word_groups (root_word, root_meaning, derivatives, examples, example_sentence_en, example_sentence_jpn, relevent)\n` +
    `select '${root_word}', '${root_meaning}', '${derivativesJson}'::jsonb, '${examplesJson}'::jsonb, ${enVal}, ${jpnVal}, ${relevent}\n` +
    `where not exists (select 1 from word_groups where root_word = '${root_word}');`
  )
}

console.log('-- Generated from supabase/vocabularies.json')
console.log('-- Paste into Supabase SQL Editor and run. Same root_word already exists => skipped.\n')
console.log(inserts.join('\n\n'))
