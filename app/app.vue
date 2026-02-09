<script setup lang="ts">
// 語根ごとの英単語（日本語補足付き）- プログラマ向け
const wordGroups = [
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

// True/False クイズ
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

const currentQuestion = computed(() => quizQuestions[currentQuestionIndex.value])
const totalQuestions = quizQuestions.length

function submitAnswer(answer: boolean) {
  userAnswer.value = answer
  showResult.value = true
  if (answer === currentQuestion.value.correct) {
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
  }
}

function resetQuiz() {
  currentQuestionIndex.value = 0
  userAnswer.value = null
  showResult.value = false
  score.value = 0
  quizFinished.value = false
}
</script>

<template>
  <div class="landing">
    <header class="hero">
      <h1>English for Japanese Programmers</h1>
      <p class="tagline">語根で覚える英単語 — カーソルから広がる語彙</p>
    </header>

    <main class="content">
      <!-- 語根・単語一覧（v-for） -->
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
            </li>
          </ul>
        </div>
      </section>

      <!-- True/False クイズ -->
      <section class="quiz">
        <h2>True / False クイズ</h2>
        <p class="section-desc">理解度を確認しましょう。</p>

        <div v-if="!quizFinished" class="quiz-box">
          <p class="question-number">
            問題 {{ currentQuestionIndex + 1 }} / {{ totalQuestions }}
          </p>
          <p class="question-statement">{{ currentQuestion.statement }}</p>

          <!-- 未回答時はボタン、回答後は結果（v-if / v-else） -->
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
              v-if="userAnswer === currentQuestion.correct"
              class="feedback correct"
            >
              ✓ 正解です！
            </p>
            <p v-else class="feedback incorrect">
              ✗ 不正解。正解は {{ currentQuestion.correct ? 'True' : 'False' }} です。
            </p>
            <button type="button" class="btn btn-next" @click="nextQuestion">
              {{ currentQuestionIndex < totalQuestions - 1 ? '次の問題' : '結果を見る' }}
            </button>
          </div>
        </div>

        <div v-else class="quiz-finished">
          <h3>クイズ結果</h3>
          <p class="score">{{ score }} / {{ totalQuestions }} 問正解</p>
          <button type="button" class="btn btn-retry" @click="resetQuiz">
            もう一度挑戦
          </button>
        </div>
      </section>
    </main>

    <footer class="footer">
      <p>Vue + Nuxt + Supabase — 日本人プログラマのための英単語</p>
    </footer>
  </div>
</template>

<style scoped>
.landing {
  min-height: 100vh;
  background: linear-gradient(160deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
  color: #e2e8f0;
  font-family: 'Segoe UI', system-ui, sans-serif;
}

.hero {
  text-align: center;
  padding: 3rem 1.5rem;
  border-bottom: 1px solid #334155;
}
.hero h1 {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  letter-spacing: -0.02em;
}
.tagline {
  margin: 0;
  color: #94a3b8;
  font-size: 1rem;
}

.content {
  max-width: 640px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.vocabulary,
.quiz {
  margin-bottom: 3rem;
}
.vocabulary h2,
.quiz h2 {
  font-size: 1.25rem;
  margin: 0 0 0.5rem;
  color: #f1f5f9;
}
.section-desc {
  margin: 0 0 1.5rem;
  color: #94a3b8;
  font-size: 0.9rem;
}

.word-group {
  background: #1e293b;
  border-radius: 12px;
  padding: 1.25rem 1.5rem;
  margin-bottom: 1rem;
  border: 1px solid #334155;
}
.root-title {
  font-size: 1rem;
  color: #38bdf8;
  margin: 0 0 0.75rem;
  font-weight: 600;
}
.word-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.word-item {
  padding: 0.4rem 0;
  border-bottom: 1px solid #334155;
  font-size: 0.95rem;
}
.word-item:last-child {
  border-bottom: none;
}
.jp {
  color: #a5b4fc;
}
.note {
  display: block;
  margin-top: 0.2rem;
  font-size: 0.85rem;
  color: #94a3b8;
}

.quiz-box {
  background: #1e293b;
  border-radius: 12px;
  padding: 1.5rem;
  border: 1px solid #334155;
}
.question-number {
  margin: 0 0 0.5rem;
  font-size: 0.85rem;
  color: #64748b;
}
.question-statement {
  margin: 0 0 1.25rem;
  font-size: 1.05rem;
  line-height: 1.5;
}
.buttons {
  display: flex;
  gap: 0.75rem;
}
.btn {
  padding: 0.6rem 1.25rem;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: opacity 0.2s;
}
.btn:hover {
  opacity: 0.9;
}
.btn-true {
  background: #22c55e;
  color: #fff;
}
.btn-false {
  background: #ef4444;
  color: #fff;
}
.btn-next,
.btn-retry {
  background: #3b82f6;
  color: #fff;
}
.result {
  margin-top: 0.5rem;
}
.feedback {
  margin: 0 0 0.75rem;
  font-weight: 600;
}
.feedback.correct {
  color: #22c55e;
}
.feedback.incorrect {
  color: #f87171;
}

.quiz-finished {
  text-align: center;
  background: #1e293b;
  border-radius: 12px;
  padding: 2rem;
  border: 1px solid #334155;
}
.quiz-finished h3 {
  margin: 0 0 0.75rem;
  font-size: 1.15rem;
}
.score {
  margin: 0 0 1.25rem;
  font-size: 1.25rem;
  color: #38bdf8;
}
.btn-retry {
  margin: 0;
}

.footer {
  text-align: center;
  padding: 2rem 1rem;
  color: #64748b;
  font-size: 0.85rem;
  border-top: 1px solid #334155;
}
.footer p {
  margin: 0;
}
</style>
