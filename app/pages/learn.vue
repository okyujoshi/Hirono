<script setup lang="ts">
type Derivative = { word: string, meaning: string }
type ExampleItem = { text: string, answer: string, jpn?: string }
type WordGroup = {
  id: number
  root_word: string
  root_meaning: string
  derivatives: Derivative[]
  examples: ExampleItem[]
  example_sentence_en: string | null
  example_sentence_jpn: string | null
  relevent: boolean
  hidden?: boolean
}

const supabase = useSupabaseClient()
const groups = ref<WordGroup[]>([])
const loading = ref(true)
const error = ref('')

/** データ整備のため一時非表示。true にすると○×クイズのメニューが表示される */
const showOxQuiz = false
const mode = ref<'fill' | 'ox' | 'review' | null>(null)
const current = ref<WordGroup | null>(null)
const todaysWord = ref<WordGroup | null>(null)
/** 今日の単語として表示中の語源のインデックス（一覧で選択用） */
const currentWordIndex = ref(0)
const currentExample = ref<ExampleItem | null>(null)
const fillInput = ref('')
const showResult = ref(false)
const userCorrect = ref(false)
const flash = ref<'correct' | 'wrong' | null>(null)
const speechEnabled = ref(true)
const revealedBlanks = ref<Record<number, boolean>>({})
const todaysFeedback = ref<'good' | 'bad' | null>(null)

/** examples の各要素を { text, answer, jpn? } に正規化（DBのキーゆれに対応） */
function normalizeExamples (raw: unknown): ExampleItem[] {
  if (!Array.isArray(raw)) return []
  return raw.map((ex: Record<string, unknown>) => {
    const text = String(ex?.text ?? '')
    const answer = String(ex?.answer ?? '')
    const jpn = ex?.jpn ?? (ex as Record<string, unknown>)?.Jpn ?? (ex as Record<string, unknown>)?.JPN
    return { text, answer, ...(jpn != null && jpn !== '' ? { jpn: String(jpn) } : {}) } as ExampleItem
  })
}

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
    const rows = (data ?? []).filter((row: Record<string, unknown>) => row.hidden !== true)
    groups.value = rows.map((row: Record<string, unknown>) => ({
      id: row.id as number,
      root_word: String(row.root_word ?? ''),
      root_meaning: String(row.root_meaning ?? ''),
      derivatives: Array.isArray(row.derivatives) ? row.derivatives as Derivative[] : [],
      examples: normalizeExamples(row.examples),
      example_sentence_en: row.example_sentence_en != null ? String(row.example_sentence_en) : null,
      example_sentence_jpn: row.example_sentence_jpn != null ? String(row.example_sentence_jpn) : null,
      relevent: Boolean(row.relevent)
    }))
  } finally {
    loading.value = false
  }
}

function pickRandom<T> (arr: T[]): T | null {
  if (!arr?.length) return null
  const item = arr[Math.floor(Math.random() * arr.length)]
  return item ?? null
}

function goToMenu () {
  mode.value = null
  current.value = null
  currentExample.value = null
  showResult.value = false
  fillInput.value = ''
}

function startQuestion () {
  showResult.value = false
  fillInput.value = ''
  const withExamples = groups.value.filter(g => g.examples?.length)
  const withFill = mode.value === 'fill' ? withExamples : groups.value
  const withReview = mode.value === 'review' ? groups.value : withFill
  if (!withReview.length) {
    current.value = null
    currentExample.value = null
    return
  }
  const row = pickRandom(withReview)
  current.value = row ?? null
  if (mode.value === 'fill' && row?.examples?.length) {
    currentExample.value = pickRandom(row.examples)
  } else {
    currentExample.value = null
  }
  if (speechEnabled.value && mode.value !== 'fill' && currentExample.value?.text) {
    speakEn(currentExample.value.text)
  }
  if (speechEnabled.value && mode.value === 'ox' && row?.root_word) {
    speakEn(row.root_word)
  }
}

/** rate: 1 = 通常, 0.52 = ゆっくり */
function speakEn (text: string, rate: number = 0.9) {
  if (typeof window === 'undefined' || !window.speechSynthesis) return
  const u = new SpeechSynthesisUtterance(text)
  u.lang = 'en-US'
  u.rate = rate
  window.speechSynthesis.cancel()
  window.speechSynthesis.speak(u)
}

function triggerFlash (correct: boolean) {
  flash.value = correct ? 'correct' : 'wrong'
  setTimeout(() => { flash.value = null }, 500)
}

function submitFill () {
  if (!current.value || !currentExample.value) return
  const correct = fillInput.value.trim().toLowerCase() === currentExample.value.answer.toLowerCase()
  userCorrect.value = correct
  showResult.value = true
  triggerFlash(correct)
}

function submitOx (value: boolean) {
  if (!current.value) return
  const correct = value === current.value.relevent
  userCorrect.value = correct
  showResult.value = true
  triggerFlash(correct)
}

function nextQuestion () {
  startQuestion()
}

const canShowFill = computed(() => current.value && currentExample.value && mode.value === 'fill')
const hasDerivatives = computed(() => (current.value?.derivatives?.length ?? 0) > 0)
const hasExampleSentence = computed(() =>
  !!(current.value?.example_sentence_en || current.value?.example_sentence_jpn)
)

onMounted(() => {
  fetchGroups()
})

function pickTodaysWord () {
  const list = [...groups.value]
  const picked = pickRandom(list)
  todaysWord.value = picked ?? null
  if (picked) {
    const idx = groups.value.findIndex(g => g.id === picked.id)
    currentWordIndex.value = idx >= 0 ? idx : 0
  }
  revealedBlanks.value = {}
  todaysFeedback.value = null
}

function goToWord (index: number) {
  const g = groups.value[index]
  if (!g) return
  todaysWord.value = g
  currentWordIndex.value = index
  revealedBlanks.value = {}
  todaysFeedback.value = null
  mode.value = null
}

function fullSentence (item: ExampleItem) {
  return (item.text || '').replace(/_{2,}/, item.answer)
}

function onBlankHover (item: ExampleItem, index: number) {
  revealedBlanks.value = { ...revealedBlanks.value, [index]: true }
  if (speechEnabled.value) speakEn(fullSentence(item))
}

function setTodaysFeedback (v: 'good' | 'bad') {
  todaysFeedback.value = v
}

function splitBlank (text: string): string[] {
  if (!text) return []
  return text.split(/(_{2,})/)
}

function isBlankPart (part: string): boolean {
  return /^_{2,}$/.test(part)
}

watch(groups, (g) => {
  if (g?.length && !todaysWord.value) {
    pickTodaysWord()
  } else if (g?.length && todaysWord.value) {
    const idx = g.findIndex(w => w.id === todaysWord.value!.id)
    currentWordIndex.value = idx >= 0 ? idx : 0
  }
}, { immediate: true })

watch([groups, mode], () => {
  if (groups.value.length && mode.value && mode.value !== null && !current.value) startQuestion()
}, { immediate: true })
</script>

<template>
  <div class="page-learn">
    <!-- 正解/不正解フラッシュ -->
    <Transition name="flash">
      <div v-if="flash" class="flash-overlay" :class="flash" />
    </Transition>

    <header class="page-header">
      <h1>プログラミング用語で覚える英会話</h1>
      <p class="page-desc">クイズで語彙を増やそう！</p>
      <button v-if="mode" type="button" class="btn-back" @click="goToMenu">← メニューに戻る</button>
    </header>

    <main class="learn-content">
      <div v-if="loading" class="card card-loading">読み込み中…</div>
      <div v-else-if="error" class="card card-error">
        {{ error }}
        <button type="button" class="btn btn-retry" @click="fetchGroups">再試行</button>
      </div>
      <div v-else-if="!groups.length" class="card card-empty">
        データがありません。Supabase の word_groups にレコードを追加してください。
      </div>

      <template v-else>
        <!-- 単語一覧（ジャンプ用・常に表示） -->
        <nav class="word-nav">
          <span class="word-nav-label">単語：</span>
          <button
            v-for="(g, i) in groups"
            :key="g.id"
            type="button"
            class="word-nav-btn"
            :class="{ active: i === currentWordIndex }"
            @click="goToWord(i)"
          >
            {{ g.root_word }}
          </button>
        </nav>

        <!-- メニュー: 今日の単語（トップ）＋ クイズ選択 -->
        <template v-if="!mode">
        <!-- 今日の単語：今日のcode / meaning / 覚えよう / 例文（ホバーで答え＋読み上げ） -->
        <section class="card todays-card">
          <h2 class="todays-heading">今日の単語 <span class="todays-badge">（ランダムに1件表示）</span></h2>
          <div v-if="todaysWord" class="todays-body">
            <p class="todays-code">今日のcode: <strong>{{ todaysWord.root_word }}</strong>
              <span v-if="speechEnabled" class="speak-buttons">
                <button type="button" class="btn-pronounce" title="発音（通常）" aria-label="発音・通常" @click="speakEn(todaysWord.root_word)">🔊</button>
                <button type="button" class="btn-pronounce btn-pronounce-slow" title="発音（ゆっくり）" aria-label="発音・ゆっくり" @click="speakEn(todaysWord.root_word, 0.52)">🐢</button>
              </span>
            </p>
            <p class="todays-meaning">基本的な意味: {{ todaysWord.root_meaning }}</p>
            <h3 class="todays-subheading">覚えよう</h3>
            <ul v-if="todaysWord.derivatives?.length" class="derivatives-list derivatives-inline">
              <li v-for="(d, i) in todaysWord.derivatives" :key="i" class="derivatives-item">
                <span class="deriv-word">{{ d.word }}</span>
                <span v-if="speechEnabled" class="speak-buttons">
                  <button type="button" class="btn-pronounce" title="発音（通常）" aria-label="発音・通常" @click="speakEn(d.word)">🔊</button>
                  <button type="button" class="btn-pronounce btn-pronounce-slow" title="発音（ゆっくり）" aria-label="発音・ゆっくり" @click="speakEn(d.word, 0.52)">🐢</button>
                </span>
                <span class="deriv-meaning">{{ d.meaning }}</span>
              </li>
            </ul>
            <h3 class="todays-subheading">例文</h3>
            <p class="todays-hint">____ にマウスを乗せると答えが表示され、英文が読み上げられます。</p>
            <div v-if="todaysWord.examples?.length" class="todays-examples">
              <div
                v-for="(ex, exIdx) in todaysWord.examples"
                :key="exIdx"
                class="example-sentence-wrap"
              >
                <p class="example-sentence-row">
                  <template v-if="ex.text">
                    <span v-for="(part, pIdx) in splitBlank(ex.text)" :key="pIdx">
                      <template v-if="isBlankPart(part)">
                        <span
                          class="blank-spot"
                          @mouseenter="onBlankHover(ex, exIdx)"
                        >
                          {{ revealedBlanks[exIdx] ? ex.answer : '____' }}
                        </span>
                      </template>
                      <template v-else>{{ part }}</template>
                    </span>
                  </template>
                </p>
                <p v-if="ex.jpn" class="example-jpn-inline">{{ ex.jpn }}</p>
              </div>
            </div>
            <div v-else-if="todaysWord.example_sentence_en || todaysWord.example_sentence_jpn" class="todays-example">
              <p v-if="todaysWord.example_sentence_en" class="example-en">{{ todaysWord.example_sentence_en }}</p>
              <p v-if="todaysWord.example_sentence_jpn" class="example-jp">{{ todaysWord.example_sentence_jpn }}</p>
            </div>
            <button type="button" class="btn btn-todays-next" @click="pickTodaysWord">別の同じ語源を表示（ランダム）</button>
            <div class="feedback-row">
              <span class="feedback-label">この内容は役に立ちましたか？</span>
              <button
                type="button"
                class="btn-feedback"
                :class="{ active: todaysFeedback === 'good' }"
                title="Good"
                @click="setTodaysFeedback('good')"
              >
                👍
              </button>
              <button
                type="button"
                class="btn-feedback"
                :class="{ active: todaysFeedback === 'bad' }"
                title="Bad"
                @click="setTodaysFeedback('bad')"
              >
                👎
              </button>
            </div>
          </div>
          <p v-else class="muted-inline">データがありません。</p>
        </section>

        <p class="menu-intro">過去に出てきた別の語源を思い出して、<button type="button" class="menu-intro-btn" @click="mode = 'fill'; startQuestion()">穴埋め挑戦</button></p>
      </template>

      <template v-else>
        <!-- クイズ中はモード切替の代わりにメニューに戻るのみ（ヘッダーに表示済み） -->

        <!-- 穴埋めクイズ -->
        <section v-if="mode === 'fill'" class="card quiz-card">
          <div v-if="!canShowFill && !showResult" class="card-inner empty-state">
            穴埋め問題があるデータがありません。
          </div>
          <template v-else-if="current && currentExample">
            <div class="card-head">
              <p class="card-label">同じ語源の意味</p>
              <p class="card-title">{{ current.root_meaning }}</p>
            </div>
            <div class="card-body">
              <p class="question-text">{{ currentExample.text }}</p>
              <p v-if="currentExample.jpn" class="example-jpn-inline fill-jpn fill-hint">
                <span class="hint-label">日本語：</span>{{ currentExample.jpn }}
              </p>
              <div v-if="!showResult" class="fill-area">
                <p class="fill-typing-hint">キーボードで入力 → Enter で答え合わせ</p>
                <div class="fill-row">
                  <input
                    v-model="fillInput"
                    type="text"
                    class="fill-input"
                    placeholder="ここに単語を入力"
                    autocomplete="off"
                    @keydown.enter="submitFill"
                  />
                  <button type="button" class="btn btn-primary" @click="submitFill">答え合わせ</button>
                </div>
              </div>
              <div v-else class="fill-result">
                <p class="result-text" :class="userCorrect ? 'correct' : 'wrong'">
                  {{ userCorrect ? '✓ 正解です！' : `✗ 正解は ${currentExample.answer} です。` }}
                </p>
                <p class="filled-sentence">{{ fullSentence(currentExample) }}</p>
                <p v-if="currentExample.jpn" class="example-jpn-inline fill-jpn">{{ currentExample.jpn }}</p>
                <span v-if="speechEnabled" class="speak-buttons speak-buttons-sentence">
                  <button type="button" class="btn-pronounce" title="全文を聴く（通常）" aria-label="全文・通常" @click="speakEn(fullSentence(currentExample))">🔊</button>
                  <button type="button" class="btn-pronounce btn-pronounce-slow" title="全文を聴く（ゆっくり）" aria-label="全文・ゆっくり" @click="speakEn(fullSentence(currentExample), 0.52)">🐢</button>
                </span>
              </div>
            </div>
          </template>
        </section>

        <!-- 復習モード（派生語・例文を表示） -->
        <section v-if="mode === 'review' && current" class="card quiz-card">
          <div class="card-head">
            <p class="card-label">同じ語源</p>
            <p class="question-word">{{ current.root_word }}</p>
            <p class="card-sub">{{ current.root_meaning }}</p>
          </div>
          <div class="card-body">
            <h3 class="review-heading">派生語</h3>
            <ul v-if="hasDerivatives" class="derivatives-list">
              <li v-for="(d, i) in current.derivatives" :key="i" class="derivatives-item">
                <span class="deriv-word">{{ d.word }}</span>
                <span v-if="speechEnabled" class="speak-buttons">
                  <button type="button" class="btn-pronounce" title="発音（通常）" aria-label="発音・通常" @click="speakEn(d.word)">🔊</button>
                  <button type="button" class="btn-pronounce btn-pronounce-slow" title="発音（ゆっくり）" aria-label="発音・ゆっくり" @click="speakEn(d.word, 0.52)">🐢</button>
                </span>
                <span class="deriv-meaning">{{ d.meaning }}</span>
              </li>
            </ul>
            <p v-else class="muted-inline">派生語は未登録です。</p>
            <div v-if="hasExampleSentence" class="example-block">
              <h3 class="example-label">参考例文</h3>
              <p v-if="current.example_sentence_en" class="example-en">{{ current.example_sentence_en }}</p>
              <p v-if="current.example_sentence_jpn" class="example-jp">{{ current.example_sentence_jpn }}</p>
            </div>
          </div>
          <div class="card-actions">
            <button type="button" class="btn btn-next" @click="startQuestion">次の同じ語源</button>
          </div>
        </section>

        <!-- ○×クイズ -->
        <section v-if="mode === 'ox'" class="card quiz-card">
          <div v-if="!current" class="card-inner empty-state">データがありません。</div>
          <template v-else>
            <div class="card-head">
              <p class="card-label">Same word group, or not?</p>
              <p class="question-word">「{{ current.root_word }}」</p>
            </div>
            <div class="card-body">
              <div v-if="!showResult" class="ox-buttons">
                <button type="button" class="btn btn-ox btn-yes" @click="submitOx(true)">
                  ○ 仲間
                </button>
                <button type="button" class="btn btn-ox btn-no" @click="submitOx(false)">
                  × 仲間ではない
                </button>
              </div>
              <div v-else class="result-text" :class="userCorrect ? 'correct' : 'wrong'">
                {{ userCorrect ? '✓ 正解です！' : '✗ 不正解です。' }}
                <span class="result-hint">（正解は {{ current.relevent ? '○ 仲間' : '× 仲間ではない' }}）</span>
              </div>
            </div>
          </template>
        </section>

        <!-- 回答後: 復習・派生語 + 参考例文 -->
        <template v-if="showResult && current">
          <div class="card review-card">
            <div class="card-head head-muted">
              <h2 class="card-title">復習・派生語</h2>
              <p class="card-sub">{{ current.root_word }} — {{ current.root_meaning }}</p>
            </div>
            <ul v-if="hasDerivatives" class="derivatives-list">
              <li v-for="(d, i) in current.derivatives" :key="i" class="derivatives-item">
                <span class="deriv-word">{{ d.word }}</span>
                <span v-if="speechEnabled" class="speak-buttons">
                  <button type="button" class="btn-pronounce" title="発音（通常）" aria-label="発音・通常" @click="speakEn(d.word)">🔊</button>
                  <button type="button" class="btn-pronounce btn-pronounce-slow" title="発音（ゆっくり）" aria-label="発音・ゆっくり" @click="speakEn(d.word, 0.52)">🐢</button>
                </span>
                <span class="deriv-meaning">{{ d.meaning }}</span>
              </li>
            </ul>
            <div v-else class="card-inner muted">派生語は未登録です。</div>

            <div v-if="hasExampleSentence" class="example-block">
              <h3 class="example-label">参考例文</h3>
              <p v-if="current.example_sentence_en" class="example-en">{{ current.example_sentence_en }}</p>
              <p v-if="current.example_sentence_jpn" class="example-jp">{{ current.example_sentence_jpn }}</p>
            </div>
          </div>

          <div class="result-actions">
            <button type="button" class="btn btn-next" @click="nextQuestion">次の問題</button>
            <button type="button" class="btn btn-menu" @click="goToMenu">メニューに戻る</button>
          </div>
        </template>
      </template>
      </template>
    </main>
  </div>
</template>

<style scoped>
.page-learn {
  padding-bottom: 2rem;
}
.page-header {
  text-align: center;
  padding: 2rem 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.page-header h1 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0 0 0.35rem;
  color: var(--text-primary);
}
.page-desc {
  margin: 0;
  font-size: 0.95rem;
  color: var(--text-muted);
}
.btn-back {
  margin-top: 0.75rem;
  padding: 0.35rem 0.75rem;
  font-size: 0.9rem;
  color: var(--hirono-blue);
  background: transparent;
  border: none;
  cursor: pointer;
}
.btn-back:hover { text-decoration: underline; }

.word-nav {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  margin: 1rem 0;
  padding: 0.75rem;
  background: #f8fafc;
  border-radius: 8px;
}
.word-nav-label {
  font-size: 0.9rem;
  color: var(--text-muted);
}
.word-nav-btn {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid var(--border-subtle);
  background: #fff;
  font-size: 0.9rem;
  cursor: pointer;
  color: var(--text-primary);
}
.word-nav-btn:hover { border-color: var(--hirono-blue); color: var(--hirono-blue); }
.word-nav-btn.active {
  background: var(--hirono-blue);
  border-color: var(--hirono-blue);
  color: #fff;
}

.todays-card {
  margin-bottom: 1.5rem;
}
.todays-heading {
  margin: 0;
  padding: 1rem 1.25rem;
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--text-primary);
  border-bottom: 1px solid var(--border-subtle);
  background: var(--bg-page);
}
.todays-badge {
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--text-muted);
}
.todays-body {
  padding: 1.25rem;
}
.todays-code {
  margin: 0 0 0.35rem;
  font-size: 1rem;
  color: var(--text-primary);
}
.todays-code strong { color: var(--hirono-blue); }
.todays-subheading {
  margin: 1rem 0 0.5rem;
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--text-primary);
}
.todays-subheading:first-of-type { margin-top: 0.5rem; }
.todays-hint {
  margin: 0 0 0.5rem;
  font-size: 0.8rem;
  color: var(--text-muted);
}
.todays-examples { margin: 0 0 0.5rem; }
.example-sentence-wrap {
  margin-bottom: 0.75rem;
}
.example-sentence-wrap:last-child { margin-bottom: 0; }
.example-sentence-row {
  margin: 0 0 0.2rem;
  font-size: 1rem;
  color: var(--text-primary);
}
.example-jpn-inline {
  margin: 0;
  font-size: 0.875rem;
  color: var(--text-muted);
  line-height: 1.4;
}
.example-jpn-inline.fill-jpn { margin-bottom: 0.5rem; }
.fill-hint .hint-label {
  font-weight: 600;
  color: var(--hirono-blue);
  margin-right: 0.25rem;
}
.blank-spot {
  display: inline;
  padding: 0.1em 0.35em;
  margin: 0 0.1em;
  border-bottom: 2px dashed var(--hirono-blue);
  cursor: pointer;
  user-select: none;
}
.blank-spot:hover { background: var(--hirono-blue-dim); }
.feedback-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border-subtle);
}
.feedback-label {
  font-size: 0.9rem;
  color: var(--text-muted);
}
.btn-feedback {
  padding: 0.4rem 0.6rem;
  font-size: 1.25rem;
  border: 1px solid var(--border-subtle);
  border-radius: 8px;
  background: var(--bg-card);
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}
.btn-feedback:hover { border-color: var(--hirono-blue-light); background: var(--hirono-blue-dim); }
.btn-feedback.active { border-color: var(--hirono-blue); background: var(--hirono-blue-dim); }
.todays-meaning {
  margin: 0 0 1rem;
  font-size: 0.95rem;
  color: var(--text-muted);
}
.derivatives-inline {
  border-top: 1px solid var(--border-subtle);
  padding-top: 0.75rem;
  margin-top: 0;
}
.todays-example {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid var(--border-subtle);
}
.todays-example .example-en { margin: 0 0 0.25rem; }
.todays-example .example-jp { margin: 0; font-size: 0.9rem; color: var(--text-muted); }
.btn-todays-next {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
  background: transparent;
  color: var(--hirono-blue);
  border: 1px solid var(--hirono-blue-light);
  border-radius: 8px;
  cursor: pointer;
}
.btn-todays-next:hover { background: var(--hirono-blue-dim); }

.menu-intro {
  margin: 0 0 1.25rem;
  font-size: 1.05rem;
  color: var(--text-primary);
}
.menu-intro-btn {
  padding: 0.35rem 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  color: #fff;
  background: var(--hirono-blue);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s, opacity 0.2s;
}
.menu-intro-btn:hover {
  background: var(--hirono-blue-light);
  opacity: 0.95;
  text-align: center;
}
.quiz-menu {
  display: grid;
  gap: 1rem;
  margin-bottom: 1.5rem;
}
.menu-card {
  display: block;
  width: 100%;
  text-align: left;
  padding: 1.25rem 1.5rem;
  background: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.menu-card:hover {
  border-color: var(--hirono-blue-light);
  box-shadow: 0 2px 8px rgba(45, 143, 191, 0.15);
}
.menu-card-icon {
  display: inline-block;
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
}
.menu-card-title {
  margin: 0 0 0.35rem;
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--text-primary);
}
.menu-card-desc {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
  color: var(--text-muted);
  line-height: 1.4;
}
.menu-card-fun {
  font-size: 0.8rem;
  color: var(--hirono-blue);
  font-weight: 500;
}
.menu-speech {
  margin-top: 0.5rem;
  justify-content: center;
}

.review-heading {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-primary);
}
.muted-inline { margin: 0; font-size: 0.9rem; color: var(--text-muted); }
.card-actions { padding: 1rem 1.25rem; border-top: 1px solid var(--border-subtle); }
.result-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 1rem;
}
.result-actions .btn-next { flex: 1; min-width: 140px; }
.btn-menu {
  padding: 1rem 1.25rem;
  background: transparent;
  color: var(--text-muted);
  border: 1px solid var(--border-subtle);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  border-radius: 8px;
}
.btn-menu:hover { color: var(--hirono-blue); border-color: var(--hirono-blue-light); }

.learn-content {
  max-width: 560px;
  margin: 0 auto;
  padding: 1.5rem;
}

.card {
  background: var(--bg-card);
  border-radius: 12px;
  border: 1px solid var(--border-subtle);
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  margin-bottom: 1rem;
  overflow: hidden;
}
.card-loading,
.card-empty,
.card-inner.empty-state,
.card-inner.muted {
  padding: 2rem;
  text-align: center;
  color: var(--text-muted);
}
.card-error {
  padding: 1.5rem;
  background: #fef2f2;
  border-color: #fecaca;
  color: #b91c1c;
}
.card-head {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--border-subtle);
}
.card-head.head-muted {
  background: var(--bg-page);
}
.card-label,
.card-sub,
.example-label {
  margin: 0 0 0.25rem;
  font-size: 0.85rem;
  color: var(--text-muted);
}
.card-title {
  margin: 0;
  font-weight: 600;
  color: var(--text-primary);
}
.question-word {
  margin: 0;
  font-size: 1.35rem;
  font-weight: 700;
  color: var(--text-primary);
}
.card-body {
  padding: 1.25rem;
}
.question-text {
  margin: 0 0 1rem;
  font-size: 1.1rem;
  font-weight: 500;
  color: var(--text-primary);
}
.fill-area { margin-top: 0.75rem; }
.fill-typing-hint {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
  color: var(--text-muted);
}
.fill-row {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  flex-wrap: wrap;
}
.fill-input {
  flex: 1;
  min-width: 200px;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  border: 2px solid #94a3b8;
  background: #fff;
  font-size: 1.05rem;
  color: var(--text-primary);
  transition: border-color 0.2s, box-shadow 0.2s;
}
.fill-input::placeholder {
  color: #94a3b8;
}
.fill-input:focus {
  outline: none;
  border-color: var(--hirono-blue);
  box-shadow: 0 0 0 3px var(--hirono-blue-dim);
}
.ox-buttons {
  display: flex;
  gap: 1rem;
}
.btn-ox {
  flex: 1;
  padding: 1rem;
  border-radius: 12px;
  font-weight: 700;
  font-size: 1.1rem;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}
.btn-yes {
  border: 2px solid var(--hirono-green);
  color: var(--hirono-green);
  background: transparent;
}
.btn-yes:hover { background: var(--hirono-green-dim); }
.btn-no {
  border: 2px solid #dc2626;
  color: #dc2626;
  background: transparent;
}
.btn-no:hover { background: rgba(220, 38, 38, 0.08); }
.result-text { margin: 0; font-weight: 500; }
.result-text.correct { color: var(--hirono-green); }
.result-text.wrong { color: #dc2626; }
.fill-result { margin-top: 0.5rem; }
.fill-result .filled-sentence {
  margin: 0.5rem 0 0;
  font-size: 1rem;
  line-height: 1.5;
  color: var(--text-primary);
}
.btn-listen-sentence {
  display: inline-block;
  margin-top: 0.5rem;
  padding: 0.35rem 0.75rem;
  border-radius: 8px;
  font-size: 0.9rem;
  border: 1px solid var(--hirono-blue-light);
  background: var(--hirono-blue-dim);
  color: var(--hirono-blue);
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}
.btn-listen-sentence:hover { background: var(--hirono-blue-light); color: #fff; }
.result-hint { font-weight: normal; color: var(--text-muted); }

.mode-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}
.btn-mode {
  padding: 0.45rem 0.9rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  border: 1px solid var(--border-subtle);
  background: var(--bg-card);
  color: var(--text-muted);
  cursor: pointer;
  transition: background 0.2s, color 0.2s, border-color 0.2s;
}
.btn-mode:hover { color: var(--text-primary); border-color: var(--hirono-blue-light); }
.btn-mode.active {
  background: var(--hirono-blue);
  color: #fff;
  border-color: var(--hirono-blue);
}
.speech-label {
  margin-left: auto;
  font-size: 0.85rem;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 0.35rem;
  cursor: pointer;
}

.btn {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: opacity 0.2s, background 0.2s;
}
.btn:hover { opacity: 0.9; }
.btn-primary {
  background: var(--hirono-blue);
  color: #fff;
}
.btn-primary:hover { background: var(--hirono-blue-light); }
.btn-retry {
  margin-top: 0.75rem;
  background: #fecaca;
  color: #b91c1c;
}
.btn-next {
  width: 100%;
  padding: 1rem;
  margin-top: 1rem;
  background: var(--hirono-blue);
  color: #fff;
  font-size: 1rem;
}

.review-card .derivatives-list {
  list-style: none;
  margin: 0;
  padding: 0;
  border-top: 1px solid var(--border-subtle);
}
.derivatives-item {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 1rem;
  padding: 0.6rem 1.25rem;
  border-bottom: 1px solid var(--border-subtle);
}
.derivatives-item:last-child { border-bottom: none; }
.deriv-word { font-weight: 600; color: var(--text-primary); }
.deriv-meaning { font-size: 0.9rem; color: var(--text-muted); }
.speak-buttons {
  display: inline-flex;
  align-items: center;
  gap: 0.2rem;
  vertical-align: middle;
}
.speak-buttons-sentence { margin-top: 0.5rem; display: inline-flex; }
.todays-code .speak-buttons { margin-left: 0.25rem; }
.derivatives-item .speak-buttons { margin-left: 0.35rem; }
.btn-pronounce {
  padding: 0.2rem 0.4rem;
  font-size: 0.9rem;
  border: none;
  border-radius: 6px;
  background: transparent;
  cursor: pointer;
  transition: background 0.2s, opacity 0.2s;
  vertical-align: middle;
}
.btn-pronounce:hover { background: var(--hirono-blue-dim); }
.btn-pronounce-slow { font-size: 0.85rem; opacity: 0.9; }
.btn-pronounce-slow:hover { opacity: 1; }
.example-block {
  padding: 1.25rem;
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-page);
}
.example-en { margin: 0 0 0.25rem; font-style: italic; color: var(--text-primary); }
.example-jp { margin: 0; font-size: 0.9rem; color: var(--text-muted); }

.flash-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  pointer-events: none;
}
.flash-overlay.correct { background: var(--hirono-green); }
.flash-overlay.wrong { background: #dc2626; }
.flash-enter-active,
.flash-leave-active { transition: opacity 0.35s ease; }
.flash-enter-from,
.flash-leave-to { opacity: 0; }
.flash-enter-to,
.flash-leave-from { opacity: 0.7; }
</style>
