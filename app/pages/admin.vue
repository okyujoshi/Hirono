<script setup lang="ts">
type Derivative = { word: string, meaning: string, explanation_jpn?: string }
type ExampleItem = { text: string, answer: string, jpn?: string }
type WordGroup = {
  id: number
  root_word: string
  root_meaning: string
  root_explanation_jpn: string | null
  derivatives: Derivative[]
  examples: ExampleItem[]
  example_sentence_en: string | null
  example_sentence_jpn: string | null
  relevent: boolean
  hidden: boolean
}

const user = useSupabaseUser()
const supabase = useSupabaseClient()
const { public: config } = useRuntimeConfig()
const adminEmail = (config.adminEmail as string) || 'hutz@nifty.com'
const isAdmin = computed(() => (user.value?.email ?? '').toLowerCase() === adminEmail.toLowerCase())

const groups = ref<WordGroup[]>([])
const loading = ref(true)
const error = ref('')
const message = ref('')

const DERIVATIVES_COUNT = 3
const EXAMPLES_COUNT = 3
const DRAFT_KEY = 'hirono-admin-add-draft'
const hasDraft = ref(false)

// フォーム（新規 / 編集共通）
const formOpen = ref(false)
const formExpanded = ref(false)
const formMode = ref<'simple' | 'json'>('simple')
const editingId = ref<number | null>(null)
const formLoading = ref(false)
const formError = ref('')

const form = ref({
  root_word: '',
  root_meaning: '',
  root_explanation_jpn: '',
  derivativesJson: '[]',
  examplesJson: '[]',
  derivativesRows: [] as { word: string, meaning: string, explanation_jpn: string }[],
  examplesRows: [] as { text: string, answer: string, jpn: string }[],
  example_sentence_en: '',
  example_sentence_jpn: '',
  relevent: true,
  hidden: false
})

async function fetchGroups () {
  loading.value = true
  error.value = ''
  try {
    const { data, error: e } = await supabase
      .from('word_groups')
      .select('*')
      .order('id')
    if (e) {
      error.value = e.message
      return
    }
    groups.value = (data ?? []).map((row: Record<string, unknown>) => ({
      id: row.id as number,
      root_word: String(row.root_word ?? ''),
      root_meaning: String(row.root_meaning ?? ''),
      root_explanation_jpn: row.root_explanation_jpn != null ? String(row.root_explanation_jpn) : null,
      derivatives: Array.isArray(row.derivatives) ? row.derivatives as Derivative[] : [],
      examples: Array.isArray(row.examples) ? row.examples as ExampleItem[] : [],
      example_sentence_en: row.example_sentence_en != null ? String(row.example_sentence_en) : null,
      example_sentence_jpn: row.example_sentence_jpn != null ? String(row.example_sentence_jpn) : null,
      relevent: Boolean(row.relevent),
      hidden: Boolean((row as Record<string, unknown>).hidden)
    }))
  } finally {
    loading.value = false
  }
}

function padDerivatives (arr: Derivative[]): { word: string, meaning: string, explanation_jpn: string }[] {
  const rows = (arr ?? []).map(d => ({
    word: d.word ?? '',
    meaning: d.meaning ?? '',
    explanation_jpn: (d as { explanation_jpn?: string }).explanation_jpn ?? ''
  }))
  while (rows.length < DERIVATIVES_COUNT) rows.push({ word: '', meaning: '', explanation_jpn: '' })
  return rows
}

function padExamples (arr: ExampleItem[]): { text: string, answer: string, jpn: string }[] {
  const rows = (arr ?? []).map(e => ({
    text: e.text ?? '',
    answer: e.answer ?? '',
    jpn: (e as { jpn?: string }).jpn ?? ''
  }))
  while (rows.length < EXAMPLES_COUNT) rows.push({ text: '', answer: '', jpn: '' })
  return rows
}

function addDerivativeRow () {
  form.value.derivativesRows.push({ word: '', meaning: '', explanation_jpn: '' })
}

function addExampleRow () {
  form.value.examplesRows.push({ text: '', answer: '', jpn: '' })
}

function saveDraft () {
  if (editingId.value != null) return
  try {
    const data = {
      root_word: form.value.root_word,
      root_meaning: form.value.root_meaning,
      root_explanation_jpn: form.value.root_explanation_jpn,
      derivativesRows: [...form.value.derivativesRows],
      examplesRows: [...form.value.examplesRows],
      example_sentence_en: form.value.example_sentence_en,
      example_sentence_jpn: form.value.example_sentence_jpn,
      relevent: form.value.relevent,
      hidden: form.value.hidden,
      formMode: formMode.value,
      derivativesJson: form.value.derivativesJson,
      examplesJson: form.value.examplesJson
    }
    localStorage.setItem(DRAFT_KEY, JSON.stringify(data))
  } catch (_) {}
}

function loadDraft () {
  try {
    const raw = localStorage.getItem(DRAFT_KEY)
    if (!raw) return
    const data = JSON.parse(raw)
    form.value.root_word = data.root_word ?? ''
    form.value.root_meaning = data.root_meaning ?? ''
    form.value.root_explanation_jpn = data.root_explanation_jpn ?? ''
    form.value.derivativesRows = Array.isArray(data.derivativesRows) ? data.derivativesRows : padDerivatives([])
    form.value.examplesRows = Array.isArray(data.examplesRows) ? data.examplesRows : padExamples([])
    form.value.example_sentence_en = data.example_sentence_en ?? ''
    form.value.example_sentence_jpn = data.example_sentence_jpn ?? ''
    form.value.relevent = data.relevent !== false
    form.value.hidden = data.hidden === true
    if (data.formMode === 'json') {
      form.value.derivativesJson = data.derivativesJson ?? '[]'
      form.value.examplesJson = data.examplesJson ?? '[]'
      formMode.value = 'json'
    }
    hasDraft.value = false
  } catch (_) {}
}

function clearDraft () {
  try {
    localStorage.removeItem(DRAFT_KEY)
    hasDraft.value = false
  } catch (_) {}
}

function openAddForm () {
  editingId.value = null
  formMode.value = 'simple'
  form.value = {
    root_word: '',
    root_meaning: '',
    root_explanation_jpn: '',
    derivativesJson: '[]',
    examplesJson: '[]',
    derivativesRows: padDerivatives([]),
    examplesRows: padExamples([]),
    example_sentence_en: '',
    example_sentence_jpn: '',
    relevent: true,
    hidden: false
  }
  formError.value = ''
  try {
    hasDraft.value = !!localStorage.getItem(DRAFT_KEY)
  } catch {
    hasDraft.value = false
  }
  formOpen.value = true
}

function openEditForm (row: WordGroup) {
  editingId.value = row.id
  formMode.value = 'simple'
  const derivatives = row.derivatives ?? []
  const examples = row.examples ?? []
  form.value = {
    root_word: row.root_word,
    root_meaning: row.root_meaning,
    root_explanation_jpn: row.root_explanation_jpn ?? '',
    derivativesJson: JSON.stringify(derivatives, null, 2),
    examplesJson: JSON.stringify(examples, null, 2),
    derivativesRows: padDerivatives(derivatives),
    examplesRows: padExamples(examples),
    example_sentence_en: row.example_sentence_en ?? '',
    example_sentence_jpn: row.example_sentence_jpn ?? '',
    relevent: row.relevent,
    hidden: row.hidden
  }
  formError.value = ''
  formOpen.value = true
}

function switchToJson () {
  form.value.derivativesJson = JSON.stringify(
    form.value.derivativesRows
      .filter(r => r.word.trim() || r.meaning.trim())
      .map(r => ({
        word: r.word.trim(),
        meaning: r.meaning.trim(),
        ...(r.explanation_jpn?.trim() ? { explanation_jpn: r.explanation_jpn.trim() } : {})
      })),
    null,
    2
  )
  form.value.examplesJson = JSON.stringify(
    form.value.examplesRows
      .filter(r => r.text.trim() || r.answer.trim())
      .map(r => ({ text: r.text.trim(), answer: r.answer.trim(), ...(r.jpn.trim() ? { jpn: r.jpn.trim() } : {}) })),
    null,
    2
  )
  formMode.value = 'json'
}

function switchToSimple () {
  const deriv = parseJson<Derivative[]>(form.value.derivativesJson, [])
  const ex = parseJson<ExampleItem[]>(form.value.examplesJson, [])
  form.value.derivativesRows = padDerivatives(deriv)
  form.value.examplesRows = padExamples(ex.map(e => ({ text: e.text, answer: e.answer, jpn: (e as { jpn?: string }).jpn ?? '' })))
  formMode.value = 'simple'
}

function closeForm () {
  if (editingId.value == null && (form.value.root_word.trim() || form.value.root_meaning.trim() || form.value.derivativesRows.some(r => r.word.trim() || r.meaning.trim()) || form.value.examplesRows.some(r => r.text.trim() || r.answer.trim()))) {
    saveDraft()
  }
  formOpen.value = false
  formExpanded.value = false
  editingId.value = null
}

function parseJson<T> (str: string, fallback: T): T {
  try {
    const v = JSON.parse(str)
    return Array.isArray(v) ? v as T : fallback
  } catch {
    return fallback
  }
}

async function submitForm () {
  formError.value = ''
  formLoading.value = true
  try {
    const derivatives: Derivative[] = formMode.value === 'simple'
      ? form.value.derivativesRows
          .filter(r => r.word.trim() || r.meaning.trim())
          .map(r => ({
            word: r.word.trim(),
            meaning: r.meaning.trim(),
            ...(r.explanation_jpn?.trim() ? { explanation_jpn: r.explanation_jpn.trim() } : {})
          }))
      : parseJson<Derivative[]>(form.value.derivativesJson, [])
    const examples: ExampleItem[] = formMode.value === 'simple'
      ? form.value.examplesRows
          .filter(r => r.text.trim() || r.answer.trim())
          .map(r => ({ text: r.text.trim(), answer: r.answer.trim(), ...(r.jpn.trim() ? { jpn: r.jpn.trim() } : {}) }))
      : parseJson<ExampleItem[]>(form.value.examplesJson, [])
    const payload = {
      root_word: form.value.root_word.trim(),
      root_meaning: form.value.root_meaning.trim(),
      root_explanation_jpn: form.value.root_explanation_jpn.trim() || null,
      derivatives,
      examples,
      example_sentence_en: form.value.example_sentence_en.trim() || null,
      example_sentence_jpn: form.value.example_sentence_jpn.trim() || null,
      relevent: form.value.relevent,
      hidden: form.value.hidden
    }
    if (!payload.root_word || !payload.root_meaning) {
      formError.value = '語源（root_word）と意味（root_meaning）は必須です。'
      return
    }

    if (editingId.value != null) {
      const { error: e } = await supabase
        .from('word_groups')
        .update(payload)
        .eq('id', editingId.value)
      if (!e) clearDraft()
      if (e) {
        formError.value = e.message
        return
      }
      message.value = '更新しました。'
    } else {
      const { error: e } = await supabase.from('word_groups').insert(payload)
      if (e) {
        formError.value = e.message
        return
      }
      message.value = '追加しました。'
      clearDraft()
    }
    closeForm()
    await fetchGroups()
    setTimeout(() => { message.value = '' }, 3000)
  } finally {
    formLoading.value = false
  }
}

async function deleteRow (row: WordGroup) {
  if (!confirm(`「${row.root_word}」を削除してよろしいですか？`)) return
  const { error: e } = await supabase.from('word_groups').delete().eq('id', row.id)
  if (e) {
    message.value = `削除に失敗しました: ${e.message}`
    return
  }
  message.value = '削除しました。'
  await fetchGroups()
  setTimeout(() => { message.value = '' }, 3000)
}

async function toggleHidden (row: WordGroup) {
  const next = !row.hidden
  const { error: e } = await supabase
    .from('word_groups')
    .update({ hidden: next })
    .eq('id', row.id)
  if (e) {
    message.value = `更新に失敗しました: ${e.message}`
    return
  }
  message.value = next ? '非表示にしました。' : '表示にしました。'
  await fetchGroups()
  setTimeout(() => { message.value = '' }, 3000)
}

onMounted(() => {
  if (isAdmin.value) fetchGroups()
})

watch(isAdmin, (ok) => {
  if (ok) fetchGroups()
})
</script>

<template>
  <div class="admin-page">
    <h1 class="admin-title">語彙管理</h1>

    <template v-if="!user">
      <p class="admin-msg">管理画面を利用するにはログインしてください。</p>
      <NuxtLink to="/" class="admin-link">トップへ</NuxtLink>
    </template>

    <template v-else-if="!isAdmin">
      <p class="admin-msg">このページは管理者（hutz@nifty.com）のみ利用できます。</p>
      <NuxtLink to="/" class="admin-link">トップへ</NuxtLink>
    </template>

    <template v-else>
      <p v-if="message" class="admin-flash">{{ message }}</p>
      <p v-if="error" class="admin-error">{{ error }}</p>

      <div class="admin-actions">
        <button type="button" class="btn-admin btn-add" @click="openAddForm">
          新規追加
        </button>
      </div>

      <div v-if="loading" class="admin-loading">読み込み中…</div>
      <div v-else class="admin-table-wrap">
        <table class="admin-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>語源</th>
              <th>意味</th>
              <th>派生語数</th>
              <th>例文数</th>
              <th>relevent</th>
              <th>表示</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="g in groups" :key="g.id" :class="{ 'row-hidden': g.hidden }">
              <td>{{ g.id }}</td>
              <td>{{ g.root_word }}</td>
              <td class="cell-meaning">{{ g.root_meaning }}</td>
              <td>{{ g.derivatives?.length ?? 0 }}</td>
              <td>{{ g.examples?.length ?? 0 }}</td>
              <td>{{ g.relevent ? '○' : '×' }}</td>
              <td>
                <span v-if="g.hidden" class="badge badge-hidden">非表示</span>
                <button v-else type="button" class="btn-admin btn-hide btn-sm" @click="toggleHidden(g)">非表示</button>
                <button v-if="g.hidden" type="button" class="btn-admin btn-show btn-sm" @click="toggleHidden(g)">表示</button>
              </td>
              <td>
                <button type="button" class="btn-admin btn-edit" @click="openEditForm(g)">編集</button>
                <button type="button" class="btn-admin btn-delete" @click="deleteRow(g)">削除</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-if="!groups.length" class="admin-empty">登録データがありません。「新規追加」または vocabularies.json + push:word-groups で投入してください。</p>
      </div>

      <!-- 新規追加 / 編集モーダル -->
      <Teleport to="body">
        <div v-if="formOpen" class="admin-overlay" @click.self="closeForm">
          <div class="admin-form-card" :class="{ 'admin-form-card--expanded': formExpanded }">
            <div class="admin-form-header">
              <h2>{{ editingId != null ? '編集' : '新規追加' }}</h2>
              <div class="admin-form-header-actions">
                <button type="button" class="btn-admin btn-outline btn-sm" @click="formExpanded = !formExpanded">
                  {{ formExpanded ? '元に戻す' : '拡大' }}
                </button>
                <button type="button" class="admin-form-close" @click="closeForm">×</button>
              </div>
            </div>
            <form class="admin-form" @submit.prevent="submitForm">
              <p v-if="formError" class="admin-form-error">{{ formError }}</p>
              <p v-if="editingId == null" class="admin-form-hint">
                語源と意味だけ入力して保存できます。派生語・例文は空のままでもOK。あとから編集で追加できます。閉じると下書き保存され、次に「新規追加」で復元できます。
              </p>
              <p v-if="editingId == null && hasDraft" class="admin-draft-actions">
                <button type="button" class="btn-admin btn-outline btn-sm" @click="loadDraft">
                  下書きを復元
                </button>
                <button type="button" class="btn-admin btn-outline btn-sm btn-link" @click="clearDraft">
                  下書きを破棄
                </button>
              </p>
              <label>
                <span>語源（root_word） *</span>
                <input v-model="form.root_word" type="text" class="admin-input" required />
              </label>
              <label>
                <span>意味（root_meaning） *</span>
                <input v-model="form.root_meaning" type="text" class="admin-input" required />
              </label>
              <label>
                <span>語源の説明（root_explanation_jpn）初心者向け・任意</span>
                <textarea v-model="form.root_explanation_jpn" class="admin-textarea admin-textarea--short" rows="3" placeholder="例：この語源はラテン語の〇〇がもとです。プログラミングでは…" />
              </label>

              <!-- Simple: derivatives + examples (add rows to enrich content) -->
              <template v-if="formMode === 'simple'">
                <div class="admin-fieldset">
                  <span class="admin-fieldset-label">派生語（{{ form.derivativesRows.length }}件）・説明は初心者ページで表示</span>
                  <div
                    v-for="(row, i) in form.derivativesRows"
                    :key="'d'+i"
                    class="admin-derivative-row"
                  >
                    <div class="admin-row">
                      <input v-model="row.word" type="text" class="admin-input admin-input--sm" placeholder="word" />
                      <input v-model="row.meaning" type="text" class="admin-input admin-input--sm" placeholder="meaning" />
                    </div>
                    <input v-model="row.explanation_jpn" type="text" class="admin-input admin-input--explain" placeholder="説明（任意）初心者向け日本語" />
                  </div>
                  <div class="admin-fieldset-actions">
                    <button type="button" class="btn-admin btn-outline btn-sm btn-add-row" @click="addDerivativeRow">
                      ＋ 派生語を1件追加
                    </button>
                    <button type="button" class="btn-admin btn-outline btn-sm btn-link" @click="switchToJson">JSON で編集</button>
                  </div>
                </div>
                <div class="admin-fieldset">
                  <span class="admin-fieldset-label">例文（{{ form.examplesRows.length }}件）空欄は ____</span>
                  <div
                    v-for="(row, i) in form.examplesRows"
                    :key="'e'+i"
                    class="admin-example-row"
                  >
                    <input v-model="row.text" type="text" class="admin-input" placeholder="Sentence with ____" />
                    <input v-model="row.answer" type="text" class="admin-input admin-input--sm" placeholder="answer" />
                    <input v-model="row.jpn" type="text" class="admin-input admin-input--sm" placeholder="日本語訳（任意）" />
                  </div>
                  <div class="admin-fieldset-actions">
                    <button type="button" class="btn-admin btn-outline btn-sm btn-add-row" @click="addExampleRow">
                      ＋ 例文を1件追加
                    </button>
                    <button type="button" class="btn-admin btn-outline btn-sm btn-link" @click="switchToJson">JSON で編集</button>
                  </div>
                </div>
              </template>
              <template v-else>
                <label>
                  <span>派生語（derivatives）JSON</span>
                  <textarea v-model="form.derivativesJson" class="admin-textarea admin-textarea--json" placeholder='[{"word":"cursor","meaning":"カーソル","explanation_jpn":"任意"}]' />
                </label>
                <label>
                  <span>例文（examples）JSON</span>
                  <textarea v-model="form.examplesJson" class="admin-textarea admin-textarea--json" placeholder='[{"text":"Move the ____ .","answer":"cursor","jpn":"…"}]' />
                </label>
                <button type="button" class="btn-admin btn-outline btn-sm" @click="switchToSimple">フォームに戻す（3件入力）</button>
              </template>

              <label>
                <span>参考例文（英語）</span>
                <input v-model="form.example_sentence_en" type="text" class="admin-input" />
              </label>
              <label>
                <span>参考例文（日本語）</span>
                <input v-model="form.example_sentence_jpn" type="text" class="admin-input" />
              </label>
              <label class="admin-check">
                <input v-model="form.relevent" type="checkbox" />
                <span>relevent（○×クイズで仲間）</span>
              </label>
              <label class="admin-check">
                <input v-model="form.hidden" type="checkbox" />
                <span>非表示（学習・初心者ページに表示しない）</span>
              </label>
              <div class="admin-form-actions">
                <button type="button" class="btn-admin btn-outline" @click="closeForm">キャンセル</button>
                <button type="submit" class="btn-admin btn-primary" :disabled="formLoading">
                  {{ formLoading ? '送信中…' : (editingId != null ? '更新' : '追加') }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </Teleport>
    </template>
  </div>
</template>

<style scoped>
.admin-page {
  max-width: 960px;
  margin: 0 auto;
  padding: 1.5rem;
}
.admin-title {
  font-size: 1.5rem;
  margin: 0 0 1rem;
  color: var(--text-primary);
}
.admin-msg {
  color: var(--text-muted);
  margin: 0 0 0.5rem;
}
.admin-link {
  color: var(--hirono-blue);
  text-decoration: none;
}
.admin-link:hover { text-decoration: underline; }
.admin-hint {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin: 0 0 0.5rem;
}
.admin-hint code {
  background: rgba(0,0,0,0.06);
  padding: 0.1rem 0.35rem;
  border-radius: 4px;
  font-size: 0.85em;
}
.admin-flash {
  padding: 0.5rem 0.75rem;
  background: #d1fae5;
  color: #065f46;
  border-radius: 8px;
  margin: 0 0 1rem;
}
.admin-error {
  padding: 0.5rem 0.75rem;
  background: #fee2e2;
  color: #991b1b;
  border-radius: 8px;
  margin: 0 0 1rem;
}
.admin-actions { margin-bottom: 1rem; }
.btn-admin {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: opacity 0.2s;
}
.btn-admin:hover:not(:disabled) { opacity: 0.9; }
.btn-admin:disabled { opacity: 0.6; cursor: not-allowed; }
.btn-add { background: var(--hirono-blue); color: #fff; }
.btn-edit { background: #0ea5e9; color: #fff; margin-right: 0.5rem; }
.btn-delete { background: #ef4444; color: #fff; }
.btn-hide { background: #f59e0b; color: #fff; margin-right: 0.25rem; }
.btn-show { background: var(--hirono-green); color: #fff; }
.btn-sm { padding: 0.35rem 0.65rem; font-size: 0.85rem; }
.btn-outline { background: transparent; color: var(--text-muted); border: 1px solid var(--border-subtle); }
.badge { font-size: 0.8rem; padding: 0.2rem 0.5rem; border-radius: 6px; }
.badge-hidden { background: #fef3c7; color: #92400e; }
.row-hidden { background: #fefce8; }
.btn-primary { background: var(--hirono-blue); color: #fff; }
.admin-loading { color: var(--text-muted); padding: 1rem 0; }
.admin-table-wrap { overflow-x: auto; }
.admin-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
}
.admin-table th,
.admin-table td {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--border-subtle);
  text-align: left;
}
.admin-table th { background: #f1f5f9; font-weight: 600; }
.cell-meaning { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.admin-empty { color: var(--text-muted); padding: 1rem 0; }

.admin-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}
.admin-form-card {
  background: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: 16px;
  padding: 1.5rem;
  width: 100%;
  max-width: 720px;
  max-height: 88vh;
  overflow-y: auto;
  box-shadow: 0 10px 40px rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
}
.admin-form-card--expanded {
  max-width: 96vw;
  width: 900px;
  height: 90vh;
  max-height: 90vh;
  padding: 1.5rem 2rem;
}
.admin-form-card--expanded .admin-textarea--json {
  min-height: 220px;
  font-size: 1rem;
}
.admin-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  flex-shrink: 0;
}
.admin-form-header h2 { margin: 0; font-size: 1.25rem; }
.admin-form-header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.btn-sm { padding: 0.35rem 0.65rem; font-size: 0.85rem; }
.admin-form-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: var(--text-muted);
  cursor: pointer;
  line-height: 1;
  padding: 0 0.25rem;
}
.admin-form-close:hover { color: var(--text-primary); }
.admin-form { display: flex; flex-direction: column; gap: 0.75rem; }
.admin-form-error { color: #dc2626; font-size: 0.9rem; margin: 0; }
.admin-form-hint {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0 0 0.25rem;
  line-height: 1.5;
  padding: 0.5rem 0.75rem;
  background: #f0f9ff;
  border-radius: 8px;
  border-left: 3px solid var(--hirono-blue);
}
.admin-draft-actions { display: flex; gap: 0.5rem; margin: 0 0 0.5rem; flex-wrap: wrap; }
.admin-form label { display: flex; flex-direction: column; gap: 0.25rem; font-size: 0.9rem; }
.admin-form label span { font-weight: 500; color: var(--text-primary); }
.admin-fieldset {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.admin-fieldset-label {
  font-weight: 500;
  color: var(--text-primary);
  font-size: 0.9rem;
}
.admin-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.5rem;
}
.admin-derivative-row {
  margin-bottom: 0.75rem;
}
.admin-derivative-row .admin-row { margin-bottom: 0.35rem; }
.admin-input--explain {
  margin-top: 0.25rem;
  font-size: 0.9rem;
}
.admin-textarea--short { min-height: 4rem; }
.admin-example-row {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.admin-example-row .admin-input--sm { max-width: 14rem; }
.admin-fieldset-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem; margin-top: 0.5rem; }
.btn-add-row { color: var(--hirono-blue); border-color: var(--hirono-blue-light); }
.btn-add-row:hover { background: var(--hirono-blue-dim); }
.btn-link { background: none; color: var(--hirono-blue); border: none; font-weight: 500; }
.btn-link:hover { text-decoration: underline; }
.admin-input {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--border-subtle);
  border-radius: 8px;
  font-size: 1rem;
}
.admin-input--sm { font-size: 0.9rem; }
.admin-input:focus { outline: none; border-color: var(--hirono-blue); }
.admin-textarea {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--border-subtle);
  border-radius: 8px;
  font-size: 0.95rem;
  font-family: ui-monospace, monospace;
  min-height: 120px;
  resize: vertical;
}
.admin-textarea--json { min-height: 140px; }
.admin-textarea:focus { outline: none; border-color: var(--hirono-blue); }
.admin-check { flex-direction: row !important; align-items: center; }
.admin-check input { width: auto; }
.admin-form-actions { display: flex; gap: 0.75rem; margin-top: 0.5rem; }
</style>
