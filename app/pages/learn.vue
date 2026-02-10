<script setup lang="ts">
const defaultWordGroups = [
  {
    root: 'cur / curs',
    meaning: '走る、流れる (run, flow)',
    words: [
      { en: 'cursor', jp: 'カーソル（画面上の位置を示す印）', note: '流れていくもの → 現在位置' },
      { en: 'current', jp: '現在の、電流、流れ', note: '今流れているもの' },
      { en: 'occur', jp: '起こる、発生する', note: '流れ向かう → 何かが起きる' },
      { en: 'recur', jp: '再発する、繰り返す', note: '再び流れる' },
      { en: 'concurrent', jp: '同時の、並行の', note: '一緒に流れる → 並行処理' }
    ]
  },
  {
    root: 'put',
    meaning: '考える (think)',
    words: [
      { en: 'compute', jp: '計算する', note: '共に考える → 計算' },
      { en: 'computer', jp: 'コンピュータ', note: '計算する機械' },
      { en: 'reputation', jp: '評判、名声', note: '繰り返し考えられること' }
    ]
  },
  {
    root: 'script',
    meaning: '書く (write)',
    words: [
      { en: 'script', jp: 'スクリプト、台本', note: '書かれたもの' },
      { en: 'description', jp: '記述、説明', note: '下に書く → 描写' },
      { en: 'prescription', jp: '処方、指示', note: '前に書く → 処方箋' }
    ]
  }
]

const wordGroups = ref<typeof defaultWordGroups>([...defaultWordGroups])

onMounted(async () => {
  try {
    const supabase = useSupabaseClient()
    const { data: groups, error: groupsError } = await supabase
      .from('word_groups')
      .select('id, root, meaning, sort_order')
      .order('sort_order')

    if (groupsError || !groups?.length) return

    const { data: wordsData, error: wordsError } = await supabase
      .from('words')
      .select('group_id, en, jp, note, example_sentence_en, example_sentence_jp, fill_blanks, sort_order')
      .order('sort_order')

    if (wordsError) return

    type FillBlankItem = { sentenceEn: string, sentenceJp: string }
    type WordRow = {
      group_id: string
      en: string
      jp: string
      note: string | null
      example_sentence_en: string | null
      example_sentence_jp: string | null
      fill_blanks: FillBlankItem[] | null
    }
    const wordsByGroupId: Record<string, Array<{ en: string, jp: string, note: string, exampleSentenceEn: string, exampleSentenceJp: string }>> = {}
    const fillBlankList: Array<{ sentenceEn: string, sentenceJp: string, answer: string }> = []
    for (const w of (wordsData ?? []) as WordRow[]) {
      const id = w.group_id
      if (!wordsByGroupId[id]) wordsByGroupId[id] = []
      wordsByGroupId[id].push({
        en: w.en,
        jp: w.jp,
        note: w.note ?? '',
        exampleSentenceEn: w.example_sentence_en ?? '',
        exampleSentenceJp: w.example_sentence_jp ?? ''
      })
      const blanks = w.fill_blanks
      if (blanks && Array.isArray(blanks) && blanks.length > 0) {
        for (const item of blanks) {
          if (item && item.sentenceEn) {
            fillBlankList.push({
              sentenceEn: item.sentenceEn,
              sentenceJp: item.sentenceJp ?? '',
              answer: w.en
            })
          }
        }
      }
    }
    fillBlankQuestions.value = fillBlankList.sort(() => Math.random() - 0.5)

    wordGroups.value = groups.map((g: { id: string, root: string, meaning: string }) => ({
      root: g.root,
      meaning: g.meaning,
      words: wordsByGroupId[g.id] ?? []
    }))
  } catch {
    // fallback のまま
  }
})

const quizQuestions = [
  { id: 1, statement: '"Cursor" と "current" は同じ語根（cur）に由来する。', correct: true },
  { id: 2, statement: '"Occur" は「流れに向かう」が語源で、「起こる」の意味になる。', correct: true },
  { id: 3, statement: '"Concurrent" は「同時・並行」を意味し、プログラミングでよく使う。', correct: true },
  { id: 4, statement: '"Compute" の語根 "put" は「置く」という意味である。', correct: false },
  { id: 5, statement: '"Script" と "description" はどちらも「書く」を意味する語根を持つ。', correct: true }
]

const currentQuestionIndex = ref(0)
const userAnswer = ref<boolean | null>(null)
const showResult = ref(false)
const score = ref(0)
const quizFinished = ref(false)
const scoreSaved = ref(false)

const currentQuestion = computed(() => quizQuestions[currentQuestionIndex.value] ?? null)
const totalQuestions = quizQuestions.length
const user = useSupabaseUser()

// 穴埋めクイズ（Supabase の words.fill_blanks JSONB から取得）
const fillBlankQuestions = ref<Array<{ sentenceEn: string, sentenceJp: string, answer: string }>>([])
const fillBlankIndex = ref(0)
const fillBlankUserInput = ref('')
const fillBlankShowResult = ref(false)
const fillBlankScore = ref(0)
const fillBlankFinished = ref(false)
const currentFillQuestion = computed(() => fillBlankQuestions.value[fillBlankIndex.value] ?? null)
const totalFillQuestions = computed(() => fillBlankQuestions.value.length)

function submitFillBlank () {
  if (!currentFillQuestion.value) return
  const correct = fillBlankUserInput.value.trim().toLowerCase() === currentFillQuestion.value.answer.toLowerCase()
  fillBlankShowResult.value = true
  if (correct) fillBlankScore.value += 1
}

function nextFillBlank () {
  fillBlankUserInput.value = ''
  fillBlankShowResult.value = false
  if (fillBlankIndex.value < totalFillQuestions.value - 1) {
    fillBlankIndex.value += 1
  } else {
    fillBlankFinished.value = true
  }
}

function resetFillBlankQuiz () {
  fillBlankIndex.value = 0
  fillBlankUserInput.value = ''
  fillBlankShowResult.value = false
  fillBlankScore.value = 0
  fillBlankFinished.value = false
  fillBlankQuestions.value = [...fillBlankQuestions.value].sort(() => Math.random() - 0.5)
}

async function saveScore () {
  if (scoreSaved.value || !user.value) return
  try {
    const supabase = useSupabaseClient()
    await supabase.from('quiz_scores').insert({
      user_id: user.value.id,
      email: user.value.email ?? '',
      score: score.value,
      total_questions: totalQuestions
    })
    scoreSaved.value = true
  } catch {
    // ignore
  }
}

function submitAnswer(answer: boolean) {
  userAnswer.value = answer
  showResult.value = true
  if (currentQuestion.value && answer === currentQuestion.value.correct) {
    score.value += 1
  }
}

function nextQuestion() {
  userAnswer.value = null
  showResult.value = false
  if (currentQuestionIndex.value < totalQuestions - 1) {
    currentQuestionIndex.value += 1
  } else {
    quizFinished.value = true
    saveScore()
  }
}

function resetQuiz() {
  currentQuestionIndex.value = 0
  userAnswer.value = null
  showResult.value = false
  score.value = 0
  quizFinished.value = false
  scoreSaved.value = false
}
</script>

<template>
  <div class="page-home">
    <header class="hero">
      <h1>English for Japanese Programmers</h1>
      <p class="tagline">語根で覚える英単語 — カーソルから広がる語彙</p>
    </header>

    <main class="content">
      <section class="vocabulary">
        <h2>語根で広げる単語</h2>
        <p class="section-desc">一つの語根から関連語をまとめて覚えましょう。</p>

        <div
          v-for="(group, gIndex) in wordGroups"
          :key="gIndex"
          class="word-group"
        >
          <h3 class="root-title">{{ group.root }} — {{ group.meaning }}</h3>
          <ul class="word-list">
            <li
              v-for="(word, wIndex) in group.words"
              :key="wIndex"
              class="word-item"
            >
              <strong>{{ word.en }}</strong>
              <span class="jp">（{{ word.jp }}）</span>
              <span v-if="word.note" class="note">— {{ word.note }}</span>
              <template v-if="word.exampleSentenceEn || word.exampleSentenceJp">
                <p class="example-sentence">
                  <span v-if="word.exampleSentenceEn" class="example-en">例: {{ word.exampleSentenceEn }}</span>
                  <span v-if="word.exampleSentenceJp" class="example-jp">（{{ word.exampleSentenceJp }}）</span>
                </p>
              </template>
            </li>
          </ul>
        </div>
      </section>

      <section class="quiz">
        <h2>True / False クイズ</h2>
        <p class="section-desc">理解度を確認しましょう。ログインするとスコアがランキングに保存されます。</p>

        <div v-if="!quizFinished && currentQuestion" class="quiz-box">
          <p class="question-number">
            問題 {{ currentQuestionIndex + 1 }} / {{ totalQuestions }}
          </p>
          <p class="question-statement">{{ currentQuestion.statement }}</p>

          <div v-if="!showResult" class="buttons">
            <button type="button" class="btn btn-true" @click="submitAnswer(true)">
              True
            </button>
            <button type="button" class="btn btn-false" @click="submitAnswer(false)">
              False
            </button>
          </div>
          <div v-else class="result">
            <p
              v-if="currentQuestion && userAnswer === currentQuestion.correct"
              class="feedback correct"
            >
              ✓ 正解です！
            </p>
            <p v-else class="feedback incorrect">
              ✗ 不正解。正解は {{ currentQuestion?.correct ? 'True' : 'False' }} です。
            </p>
            <button type="button" class="btn btn-next" @click="nextQuestion">
              {{ currentQuestionIndex < totalQuestions - 1 ? '次の問題' : '結果を見る' }}
            </button>
          </div>
        </div>

        <div v-else class="quiz-finished">
          <h3>クイズ結果</h3>
          <p class="score">{{ score }} / {{ totalQuestions }} 問正解</p>
          <p v-if="user && scoreSaved" class="score-saved">ランキングに保存しました</p>
          <p v-else-if="user && !scoreSaved" class="score-saved muted">保存中…</p>
          <p v-else class="score-saved muted">ログインするとスコアがランキングに記録されます</p>
          <div class="quiz-finished-actions">
            <NuxtLink to="/ranking" class="btn btn-ranking">ランキングを見る</NuxtLink>
            <button type="button" class="btn btn-retry" @click="resetQuiz">
              もう一度挑戦
            </button>
          </div>
        </div>
      </section>

      <!-- 穴埋めクイズ（fill_blanks JSONB） -->
      <section class="fill-blank-quiz">
        <h2>穴埋めクイズ</h2>
        <p class="section-desc">例文の ___ に当てはまる英単語を入力しましょう。単語・例文は Supabase の words テーブル「fill_blanks」で管理できます。</p>

        <div v-if="totalFillQuestions === 0" class="quiz-box no-items">
          <p>穴埋め問題がまだありません。Supabase の <strong>words</strong> テーブルで <strong>fill_blanks</strong> カラムに JSON を追加してください。</p>
          <p class="hint">例: <code>[{"sentenceEn": "Move the ___ to the end.", "sentenceJp": "___を行末に移動する。"}]</code></p>
        </div>

        <template v-else>
          <div v-if="!fillBlankFinished && currentFillQuestion" class="quiz-box fill-box">
            <p class="question-number">穴埋め {{ fillBlankIndex + 1 }} / {{ totalFillQuestions }}</p>
            <p class="sentence-en">{{ currentFillQuestion.sentenceEn }}</p>
            <p v-if="currentFillQuestion.sentenceJp" class="sentence-jp">{{ currentFillQuestion.sentenceJp }}</p>

            <div v-if="!fillBlankShowResult" class="fill-input-row">
              <input
                v-model="fillBlankUserInput"
                type="text"
                class="fill-input"
                placeholder="空欄の単語を入力"
                @keydown.enter="submitFillBlank"
              />
              <button type="button" class="btn btn-submit-fill" @click="submitFillBlank">答え合わせ</button>
            </div>
            <div v-else class="fill-result">
              <p v-if="fillBlankUserInput.trim().toLowerCase() === currentFillQuestion.answer.toLowerCase()" class="feedback correct">✓ 正解です！</p>
              <p v-else class="feedback incorrect">✗ 正解は <strong>{{ currentFillQuestion.answer }}</strong> です。</p>
              <button type="button" class="btn btn-next" @click="nextFillBlank">
                {{ fillBlankIndex < totalFillQuestions - 1 ? '次の問題' : '結果を見る' }}
              </button>
            </div>
          </div>

          <div v-else class="quiz-finished fill-finished">
            <h3>穴埋めクイズ結果</h3>
            <p class="score">{{ fillBlankScore }} / {{ totalFillQuestions }} 問正解</p>
            <button type="button" class="btn btn-retry" @click="resetFillBlankQuiz">もう一度挑戦</button>
          </div>
        </template>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page-home { padding-bottom: 2rem; }

.hero {
  text-align: center;
  padding: 3rem 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.hero h1 {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}
.tagline { margin: 0; color: var(--text-muted); font-size: 1rem; }

.content {
  max-width: 640px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.vocabulary, .quiz { margin-bottom: 3rem; }
.vocabulary h2, .quiz h2 {
  font-size: 1.25rem;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.section-desc { margin: 0 0 1.5rem; color: var(--text-muted); font-size: 0.9rem; }

.word-group {
  background: var(--bg-card);
  border-radius: 12px;
  padding: 1.25rem 1.5rem;
  margin-bottom: 1rem;
  border: 1px solid var(--border-subtle);
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.root-title {
  font-size: 1rem;
  color: var(--hirono-blue);
  margin: 0 0 0.75rem;
  font-weight: 600;
}
.word-list { list-style: none; margin: 0; padding: 0; }
.word-item {
  padding: 0.4rem 0;
  border-bottom: 1px solid var(--border-subtle);
  font-size: 0.95rem;
  color: var(--text-primary);
}
.word-item:last-child { border-bottom: none; }
.jp { color: #475569; }
.note { display: block; margin-top: 0.2rem; font-size: 0.85rem; color: var(--text-muted); }
.example-sentence { margin: 0.35rem 0 0; font-size: 0.9rem; }
.example-en { font-style: italic; color: #475569; }
.example-jp { color: var(--text-muted); margin-left: 0.25rem; }

.quiz-box {
  background: var(--bg-card);
  border-radius: 12px;
  padding: 1.5rem;
  border: 1px solid var(--border-subtle);
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.question-number { margin: 0 0 0.5rem; font-size: 0.85rem; color: var(--text-muted); }
.question-statement { margin: 0 0 1.25rem; font-size: 1.05rem; line-height: 1.5; color: var(--text-primary); }
.buttons { display: flex; gap: 0.75rem; }
.btn {
  padding: 0.6rem 1.25rem;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: opacity 0.2s, background 0.2s;
  text-decoration: none;
  display: inline-block;
}
.btn:hover { opacity: 0.95; }
.btn-true { background: var(--hirono-green); color: #fff; }
.btn-true:hover { background: var(--hirono-green-light); }
.btn-false { background: #dc6b6b; color: #fff; }
.btn-next, .btn-retry { background: var(--hirono-blue); color: #fff; }
.btn-next:hover, .btn-retry:hover { background: var(--hirono-blue-light); }
.btn-ranking { background: var(--hirono-blue); color: #fff; margin-right: 0.5rem; }
.btn-ranking:hover { background: var(--hirono-blue-light); }
.result { margin-top: 0.5rem; }
.feedback { margin: 0 0 0.75rem; font-weight: 600; }
.feedback.correct { color: var(--hirono-green); }
.feedback.incorrect { color: #c53030; }

.quiz-finished {
  text-align: center;
  background: var(--bg-card);
  border-radius: 12px;
  padding: 2rem;
  border: 1px solid var(--border-subtle);
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.quiz-finished h3 { margin: 0 0 0.75rem; font-size: 1.15rem; color: var(--text-primary); }
.score { margin: 0 0 0.5rem; font-size: 1.25rem; color: var(--hirono-blue); }
.score-saved { margin: 0 0 1rem; font-size: 0.9rem; color: var(--text-muted); }
.score-saved.muted { color: var(--text-muted); }
.quiz-finished-actions { margin-top: 1rem; }

/* 穴埋めクイズ */
.fill-blank-quiz { margin-bottom: 3rem; }
.fill-blank-quiz h2 { font-size: 1.25rem; margin: 0 0 0.5rem; color: var(--text-primary); }
.no-items { color: var(--text-muted); }
.no-items code { font-size: 0.85rem; background: #f1f5f9; padding: 0.2rem 0.4rem; border-radius: 4px; color: var(--text-primary); }
.no-items .hint { margin-top: 0.75rem; font-size: 0.9rem; }
.fill-box .sentence-en { font-size: 1.1rem; margin: 0 0 0.25rem; color: var(--text-primary); }
.fill-box .sentence-jp { font-size: 0.95rem; color: var(--text-muted); margin: 0 0 1rem; }
.fill-input-row { display: flex; gap: 0.5rem; align-items: center; flex-wrap: wrap; }
.fill-input {
  flex: 1;
  min-width: 140px;
  padding: 0.55rem 0.75rem;
  border-radius: 8px;
  border: 1px solid var(--border-subtle);
  background: #f8fafc;
  color: var(--text-primary);
  font-size: 1rem;
}
.fill-input:focus { outline: none; border-color: var(--hirono-blue); background: #fff; }
.btn-submit-fill { background: var(--hirono-green); color: #fff; }
.btn-submit-fill:hover { background: var(--hirono-green-light); }
.fill-result { margin-top: 0.5rem; }
.fill-finished .score { margin: 0 0 1rem; }
</style>
