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
}

const supabase = useSupabaseClient()
const lessons = ref<WordGroup[]>([])
const loading = ref(true)
const error = ref('')
const currentIndex = ref(0)
const speechEnabled = ref(true)

function normalizeExamples (raw: unknown): ExampleItem[] {
  if (!Array.isArray(raw)) return []
  return raw.map((ex: Record<string, unknown>) => {
    const text = String(ex?.text ?? '')
    const answer = String(ex?.answer ?? '')
    const jpn = ex?.jpn ?? (ex as Record<string, unknown>)?.Jpn ?? (ex as Record<string, unknown>)?.JPN
    return { text, answer, ...(jpn != null && jpn !== '' ? { jpn: String(jpn) } : {}) } as ExampleItem
  })
}

async function fetchLessons () {
  loading.value = true
  error.value = ''
  try {
    const { data, error: e } = await supabase
      .from('word_groups')
      .select('*')
      .eq('relevent', true)
      .order('id')
    if (e) {
      error.value = e.message
      return
    }
    lessons.value = (data ?? []).map((row: Record<string, unknown>) => ({
      id: row.id as number,
      root_word: String(row.root_word ?? ''),
      root_meaning: String(row.root_meaning ?? ''),
      root_explanation_jpn: row.root_explanation_jpn != null ? String(row.root_explanation_jpn) : null,
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

const currentLesson = computed(() => lessons.value[currentIndex.value] ?? null)
const hasPrev = computed(() => currentIndex.value > 0)
const hasNext = computed(() => currentIndex.value < lessons.value.length - 1 && lessons.value.length > 0)

/** 絶対初心者向け：派生語1つずつ + その単語を使う例文をセットにしたステップ配列 */
const lessonSteps = computed(() => {
  const lesson = currentLesson.value
  if (!lesson?.derivatives?.length) return []
  const examples = lesson.examples ?? []
  const norm = (s: string) => (s || '').trim().toLowerCase()
  return lesson.derivatives.map((d, i) => {
    const wordKey = norm(d.word)
    const forThisWord = examples.filter(ex => norm(ex.answer) === wordKey)
    return { index: i + 1, derivative: d, examples: forThisWord }
  })
})

function goPrev () {
  if (hasPrev.value) currentIndex.value--
}
function goNext () {
  if (hasNext.value) currentIndex.value++
}
function goToLesson (index: number) {
  currentIndex.value = index
}

function fullSentence (ex: ExampleItem) {
  return (ex.text || '').replace(/_{2,}/, ex.answer)
}
/** rate: 1 = 通常, 0.5 = ゆっくり */
function speakEn (text: string, rate: number = 0.9) {
  if (typeof window === 'undefined' || !window.speechSynthesis) return
  const u = new SpeechSynthesisUtterance(text)
  u.lang = 'en-US'
  u.rate = rate
  window.speechSynthesis.cancel()
  window.speechSynthesis.speak(u)
}

onMounted(() => fetchLessons())
</script>

<template>
  <div class="page-beginner">
    <header class="page-header">
      <h1 class="page-title">初心者レッスン</h1>
      <p class="page-desc">
        同じ語源の単語を、<strong>ひとつずつ</strong>日本語でていねいに解説します。
        それぞれの単語の意味を確認したあと、その単語が英文でどう使われるかを例文で見ていきます。英語が苦手な方も、無理せず読んでいきましょう。
      </p>
    </header>

    <p v-if="error" class="error-msg">{{ error }}</p>
    <div v-else-if="loading" class="loading-msg">読み込み中…</div>

    <template v-else-if="lessons.length === 0">
      <p class="empty-msg">レッスンがありません。</p>
    </template>

    <template v-else>
      <!-- レッスン一覧（ジャンプ用） -->
      <nav class="lesson-nav">
        <span class="lesson-nav-label">レッスン：</span>
        <button
          v-for="(lesson, i) in lessons"
          :key="lesson.id"
          type="button"
          class="lesson-nav-btn"
          :class="{ active: i === currentIndex }"
          @click="goToLesson(i)"
        >
          {{ lesson.root_word }}
        </button>
      </nav>

      <!-- 前へ・次へ -->
      <div class="lesson-pager">
        <button type="button" class="btn-pager" :disabled="!hasPrev" @click="goPrev">
          ← 前のレッスン
        </button>
        <span class="pager-info">{{ currentIndex + 1 }} / {{ lessons.length }}</span>
        <button type="button" class="btn-pager" :disabled="!hasNext" @click="goNext">
          次のレッスン →
        </button>
      </div>

      <!-- 現在のレッスン -->
      <article v-if="currentLesson" class="lesson-card">
        <h2 class="lesson-root">
          <span class="lesson-root-label">語源</span>
          <span class="lesson-root-word">{{ currentLesson.root_word }}</span>
        </h2>
        <p class="lesson-root-meaning">{{ currentLesson.root_meaning }}</p>
        <p v-if="currentLesson.root_explanation_jpn" class="lesson-root-explanation">
          {{ currentLesson.root_explanation_jpn }}
        </p>
        <div class="lesson-intro">
          <p>
            <strong>「{{ currentLesson.root_word }}」</strong> は、上の意味を持つ語源です。
            <template v-if="!currentLesson.root_explanation_jpn">プログラミングでよく出てくる英単語の多くは、こんな語源が組み合わさってできています。</template>
          </p>
          <p>
            これから、この語源からできた単語を<strong>ひとつずつ</strong>見ていきます。
            それぞれの単語の意味を日本語で説明したあと、その単語が実際の英文でどう使われるかを例文で確認します。
          </p>
        </div>

        <!-- 絶対初心者向け：派生語1つ → その単語の例文、の順で繰り返し -->
        <section v-for="step in lessonSteps" :key="step.derivative.word" class="lesson-step">
          <h3 class="step-title">その{{ step.index }} — {{ step.derivative.word }}</h3>
          <p class="step-intro">
            まず<strong>「{{ step.derivative.word }}」</strong>という単語を見ていきましょう。
          </p>
          <div class="derivative-block">
            <p class="deriv-line">
              <span class="deriv-word">{{ step.derivative.word }}</span>
              <span v-if="speechEnabled" class="speak-buttons">
                <button type="button" class="btn-speak" title="発音（通常）" aria-label="発音・通常" @click="speakEn(step.derivative.word)">
                  🔊
                </button>
                <button type="button" class="btn-speak btn-speak-slow" title="発音（ゆっくり）" aria-label="発音・ゆっくり" @click="speakEn(step.derivative.word, 0.52)">
                  🐢
                </button>
              </span>
              <span class="deriv-meaning">＝ {{ step.derivative.meaning }}</span>
            </p>
            <p class="deriv-explain">
              <template v-if="step.derivative.explanation_jpn">
                {{ step.derivative.explanation_jpn }}
              </template>
              <template v-else>
                <strong>{{ step.derivative.word }}</strong> は「{{ step.derivative.meaning }}」という意味の英単語です。
                プログラミングの画面や説明文では、この意味でよく使われます。覚えておくと、英語のドキュメントを読むときにも役立ちます。
              </template>
            </p>
          </div>

          <template v-if="step.examples.length">
            <p class="example-intro">
              では、この単語が実際の英文でどう使われるか、例文で見てみましょう。次の文の <strong>____</strong> のところに、<strong>「{{ step.derivative.word }}」</strong> が入ります。
            </p>
            <div v-for="(ex, ei) in step.examples" :key="ei" class="example-block">
              <p class="example-en">
                <span v-if="speechEnabled" class="speak-buttons-inline">
                  <button type="button" class="btn-speak-inline" title="読み上げ（通常）" aria-label="読み上げ・通常" @click="speakEn(fullSentence(ex))">
                    🔊
                  </button>
                  <button type="button" class="btn-speak-inline btn-speak-slow" title="読み上げ（ゆっくり）" aria-label="読み上げ・ゆっくり" @click="speakEn(fullSentence(ex), 0.52)">
                    🐢
                  </button>
                </span>
                {{ ex.text }}
              </p>
              <p v-if="ex.jpn" class="example-jpn">日本語訳：{{ ex.jpn }}</p>
              <p class="example-answer">空欄の答え：<strong>{{ ex.answer }}</strong></p>
              <p class="example-note">
                つまり、この文は「{{ ex.jpn || (ex.answer + ' が入る文です。') }}」という意味になります。
              </p>
            </div>
          </template>
          <p v-else class="no-example">
            この単語を使った例文は、現在ありません。上の「{{ step.derivative.meaning }}」という意味だけ、まず覚えておきましょう。
          </p>
        </section>

        <p v-if="!currentLesson.derivatives?.length" class="muted">この語源の派生語は未登録です。</p>

        <div v-if="currentLesson.example_sentence_en || currentLesson.example_sentence_jpn" class="lesson-section reference">
          <h3 class="section-title">参考例文</h3>
          <p v-if="currentLesson.example_sentence_en" class="example-en">
            <span v-if="speechEnabled" class="speak-buttons-inline">
              <button type="button" class="btn-speak-inline" title="読み上げ（通常）" aria-label="読み上げ・通常" @click="speakEn(currentLesson.example_sentence_en!)">
                🔊
              </button>
              <button type="button" class="btn-speak-inline btn-speak-slow" title="読み上げ（ゆっくり）" aria-label="読み上げ・ゆっくり" @click="speakEn(currentLesson.example_sentence_en!, 0.52)">
                🐢
              </button>
            </span>
            {{ currentLesson.example_sentence_en }}
          </p>
          <p v-if="currentLesson.example_sentence_jpn" class="example-jpn">{{ currentLesson.example_sentence_jpn }}</p>
        </div>

        <div class="lesson-footer">
          <button type="button" class="btn-next-lesson" :disabled="!hasNext" @click="goNext">
            次のレッスンへ →
          </button>
        </div>
      </article>
    </template>
  </div>
</template>

<style scoped>
.page-beginner {
  max-width: 720px;
  margin: 0 auto;
  padding: 1.5rem;
  padding-bottom: 3rem;
}
.page-header {
  text-align: center;
  padding: 2rem 0 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.page-title {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.page-desc {
  margin: 0;
  font-size: 1rem;
  color: var(--text-muted);
  line-height: 1.6;
}
.error-msg {
  padding: 1rem;
  background: #fee2e2;
  color: #991b1b;
  border-radius: 8px;
  margin: 1rem 0;
}
.loading-msg, .empty-msg {
  text-align: center;
  color: var(--text-muted);
  padding: 2rem;
}

.lesson-nav {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  margin: 1rem 0;
  padding: 0.75rem;
  background: #f8fafc;
  border-radius: 8px;
}
.lesson-nav-label {
  font-size: 0.9rem;
  color: var(--text-muted);
}
.lesson-nav-btn {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid var(--border-subtle);
  background: #fff;
  font-size: 0.9rem;
  cursor: pointer;
  color: var(--text-primary);
}
.lesson-nav-btn:hover { border-color: var(--hirono-blue); color: var(--hirono-blue); }
.lesson-nav-btn.active {
  background: var(--hirono-blue);
  border-color: var(--hirono-blue);
  color: #fff;
}

.lesson-pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin: 1rem 0;
}
.btn-pager {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1px solid var(--border-subtle);
  background: #fff;
  font-size: 0.9rem;
  cursor: pointer;
  color: var(--text-primary);
}
.btn-pager:hover:not(:disabled) { border-color: var(--hirono-blue); color: var(--hirono-blue); }
.btn-pager:disabled { opacity: 0.5; cursor: not-allowed; }
.pager-info { font-size: 0.9rem; color: var(--text-muted); }

.lesson-card {
  background: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: 16px;
  padding: 1.5rem 2rem;
  margin-top: 1rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}
.lesson-root {
  margin: 0 0 0.35rem;
  font-size: 1.35rem;
}
.lesson-root-label {
  display: block;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}
.lesson-root-word {
  color: var(--hirono-blue);
  font-weight: 700;
}
.lesson-root-meaning {
  margin: 0 0 0.75rem;
  font-size: 1.1rem;
  color: var(--text-primary);
}
.lesson-root-explanation {
  margin: 0 0 1.25rem;
  font-size: 0.98rem;
  line-height: 1.7;
  color: var(--text-primary);
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-subtle);
}
.lesson-intro {
  margin-bottom: 1.5rem;
}
.lesson-intro p {
  margin: 0;
  line-height: 1.75;
  color: var(--text-primary);
  font-size: 1rem;
}

.lesson-section {
  margin-bottom: 2rem;
}
.lesson-section.reference { margin-bottom: 1rem; }
.section-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0 0 0.35rem;
  color: var(--text-primary);
}
.section-note {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin: 0 0 1rem;
  line-height: 1.5;
}

.lesson-step {
  margin-bottom: 2.5rem;
  padding: 1.25rem;
  background: #fafbfc;
  border-radius: 12px;
  border: 1px solid var(--border-subtle);
}
.step-title {
  font-size: 1.15rem;
  font-weight: 700;
  margin: 0 0 0.75rem;
  color: var(--hirono-blue);
  padding-bottom: 0.5rem;
  border-bottom: 2px solid var(--hirono-blue);
}
.step-intro {
  margin: 0 0 1rem;
  font-size: 0.98rem;
  line-height: 1.65;
  color: var(--text-primary);
}
.derivative-block {
  margin-bottom: 1rem;
}
.deriv-line {
  margin: 0 0 0.5rem;
  font-size: 1.05rem;
}
.deriv-word {
  font-weight: 700;
  font-size: 1.05rem;
  color: var(--text-primary);
}
.deriv-meaning {
  margin-left: 0.35rem;
  color: var(--text-muted);
  font-size: 0.95rem;
}
.deriv-explain {
  margin: 0.5rem 0 0;
  font-size: 0.95rem;
  line-height: 1.65;
  color: var(--text-primary);
}
.example-intro {
  margin: 1rem 0 0.75rem;
  font-size: 0.95rem;
  line-height: 1.6;
  color: var(--text-primary);
}
.no-example {
  margin: 1rem 0 0;
  font-size: 0.9rem;
  color: var(--text-muted);
  font-style: italic;
  line-height: 1.5;
}
.speak-buttons { display: inline-flex; align-items: center; gap: 0.25rem; margin-left: 0.5rem; }
.speak-buttons-inline { display: inline-flex; align-items: center; gap: 0.2rem; margin-right: 0.35rem; }
.btn-speak,
.btn-speak-inline {
  padding: 0.2rem 0.4rem;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 1rem;
  vertical-align: middle;
}
.btn-speak-slow { font-size: 0.85rem; opacity: 0.9; }
.btn-speak:hover,
.btn-speak-inline:hover { opacity: 0.8; }
.btn-speak-slow:hover { opacity: 1; }

.example-block {
  padding: 1rem;
  margin-bottom: 1rem;
  background: #f8fafc;
  border-radius: 10px;
}
.example-en {
  margin: 0 0 0.5rem;
  font-size: 1rem;
  line-height: 1.6;
  color: var(--text-primary);
}
.example-jpn {
  margin: 0 0 0.35rem;
  font-size: 0.95rem;
  color: #166534;
  line-height: 1.5;
}
.example-answer {
  margin: 0.5rem 0 0.25rem;
  font-size: 0.9rem;
  color: var(--text-muted);
}
.example-answer strong { color: var(--text-primary); }
.example-note {
  margin: 0.5rem 0 0;
  font-size: 0.9rem;
  line-height: 1.55;
  color: var(--text-muted);
}

.muted { color: var(--text-muted); font-size: 0.9rem; margin: 0; }

.lesson-footer {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--border-subtle);
  text-align: center;
}
.btn-next-lesson {
  padding: 0.65rem 1.25rem;
  border-radius: 8px;
  border: none;
  background: var(--hirono-blue);
  color: #fff;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
}
.btn-next-lesson:hover:not(:disabled) { opacity: 0.95; }
.btn-next-lesson:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
