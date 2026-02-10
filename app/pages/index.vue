<script setup lang="ts">
const openAuth = inject<(mode: 'login' | 'signup') => void>('openAuth')

// 学習内容サンプル（表示のみ）
const sampleWordGroups = [
  {
    root: 'cur / curs',
    meaning: '走る、流れる (run, flow)',
    words: [
      { en: 'cursor', jp: 'カーソル（画面上の位置を示す印）', note: '流れていくもの → 現在位置' },
      { en: 'current', jp: '現在の、電流、流れ', note: '今流れているもの' },
      { en: 'occur', jp: '起こる、発生する', note: '流れ向かう → 何かが起きる' }
    ]
  },
  {
    root: 'put',
    meaning: '考える (think)',
    words: [
      { en: 'compute', jp: '計算する', note: '共に考える → 計算' },
      { en: 'computer', jp: 'コンピュータ', note: '計算する機械' }
    ]
  }
]

const sampleQuestions = [
  { id: 1, statement: '"Cursor" と "current" は同じ語根（cur）に由来する。', correct: true },
  { id: 2, statement: '"Concurrent" は「同時・並行」を意味し、プログラミングでよく使う。', correct: true }
]

const currentIndex = ref(0)
const userAnswer = ref<boolean | null>(null)
const showResult = ref(false)
const sampleScore = ref(0)
const sampleFinished = ref(false)

const currentQuestion = computed(() => sampleQuestions[currentIndex.value] ?? null)
const totalSample = sampleQuestions.length

function submitAnswer (answer: boolean) {
  userAnswer.value = answer
  showResult.value = true
  if (currentQuestion.value && answer === currentQuestion.value.correct) {
    sampleScore.value += 1
  }
}

function nextQuestion () {
  userAnswer.value = null
  showResult.value = false
  if (currentIndex.value < totalSample - 1) {
    currentIndex.value += 1
  } else {
    sampleFinished.value = true
  }
}

function tryAgain () {
  currentIndex.value = 0
  userAnswer.value = null
  showResult.value = false
  sampleScore.value = 0
  sampleFinished.value = false
}
</script>

<template>
  <div class="page-sample">
    <!-- トップ CTA: 登録を促す -->
    <section class="cta-banner">
      <div class="cta-inner">
        <h2 class="cta-title">無料登録で、スコアを保存してランキングに参加しよう</h2>
        <p class="cta-desc">語根で英単語を学び、クイズに挑戦。登録するとスコアが記録され、ランキングで競えます。</p>
        <button type="button" class="btn-cta" @click="openAuth?.('signup')">
          無料で新規登録
        </button>
        <p class="cta-login">
          すでにアカウントがある方は
          <button type="button" class="link-btn" @click="openAuth?.('login')">ログイン</button>
        </p>
      </div>
    </section>

    <header class="hero">
      <h1>English for Japanese Programmers</h1>
      <p class="tagline">まずはお試し — 語根クイズを2問体験</p>
    </header>

    <main class="content">
      <!-- 学習内容サンプル（表示のみ） -->
      <section class="sample-content">
        <h2>学習内容のサンプル</h2>
        <p class="section-desc">語根から関連する英単語をまとめて覚えます。登録するとさらに多くの語根・単語とクイズが利用できます。</p>
        <div
          v-for="(group, gIndex) in sampleWordGroups"
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

      <section class="sample-quiz">
        <h2>お試しクイズ</h2>
        <p class="section-desc">体験してみましょう。続きは無料登録で全5問＋ランキングが利用できます。</p>

        <div v-if="!sampleFinished && currentQuestion" class="quiz-box">
          <p class="question-number">問題 {{ currentIndex + 1 }} / {{ totalSample }}</p>
          <p class="question-statement">{{ currentQuestion.statement }}</p>

          <div v-if="!showResult" class="buttons">
            <button type="button" class="btn btn-true" @click="submitAnswer(true)">True</button>
            <button type="button" class="btn btn-false" @click="submitAnswer(false)">False</button>
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
              {{ currentIndex < totalSample - 1 ? '次の問題' : '結果を見る' }}
            </button>
          </div>
        </div>

        <div v-else class="quiz-finished">
          <h3>お試しクイズ結果</h3>
          <p class="score">{{ sampleScore }} / {{ totalSample }} 問正解</p>
          <p class="cta-after">無料登録すると、全5問のクイズとランキングが使えます。</p>
          <div class="actions">
            <button type="button" class="btn btn-signup" @click="openAuth?.('signup')">
              無料で登録して続きをプレイ
            </button>
            <NuxtLink to="/learn" class="btn btn-learn">学習ページへ（語彙・全問クイズ）</NuxtLink>
            <button type="button" class="btn btn-retry" @click="tryAgain">もう一度お試しクイズ</button>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page-sample { padding-bottom: 3rem; }

.cta-banner {
  background: linear-gradient(135deg, rgba(45, 143, 191, 0.12) 0%, rgba(58, 155, 74, 0.08) 50%, rgba(255,255,255,0.5) 100%);
  border-bottom: 1px solid var(--border-subtle);
  padding: 1.5rem 1rem;
}
.cta-inner {
  max-width: 640px;
  margin: 0 auto;
  text-align: center;
}
.cta-title {
  font-size: 1.15rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.cta-desc {
  margin: 0 0 1rem;
  font-size: 0.9rem;
  color: var(--text-muted);
  line-height: 1.5;
}
.btn-cta {
  display: inline-block;
  padding: 0.7rem 1.5rem;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 600;
  border: none;
  cursor: pointer;
  background: var(--hirono-green);
  color: #fff;
  transition: background 0.2s, opacity 0.2s;
}
.btn-cta:hover { background: var(--hirono-green-light); opacity: 0.95; }
.cta-login {
  margin: 0.75rem 0 0;
  font-size: 0.9rem;
  color: var(--text-muted);
}
.link-btn {
  background: none;
  border: none;
  color: var(--hirono-blue);
  cursor: pointer;
  text-decoration: underline;
  padding: 0;
  font-size: inherit;
}
.link-btn:hover { color: var(--hirono-blue-light); }

.hero {
  text-align: center;
  padding: 2.5rem 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.hero h1 {
  font-size: 1.6rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}
.tagline { margin: 0; color: var(--text-muted); font-size: 0.95rem; }

.content {
  max-width: 640px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.sample-content { margin-bottom: 2.5rem; }
.sample-content h2 {
  font-size: 1.25rem;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.sample-content .word-group {
  background: var(--bg-card);
  border-radius: 12px;
  padding: 1.25rem 1.5rem;
  margin-bottom: 1rem;
  border: 1px solid var(--border-subtle);
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.sample-content .root-title {
  font-size: 1rem;
  color: var(--hirono-blue);
  margin: 0 0 0.75rem;
  font-weight: 600;
}
.sample-content .word-list { list-style: none; margin: 0; padding: 0; }
.sample-content .word-item {
  padding: 0.4rem 0;
  border-bottom: 1px solid var(--border-subtle);
  font-size: 0.95rem;
  color: var(--text-primary);
}
.sample-content .word-item:last-child { border-bottom: none; }
.sample-content .jp { color: #475569; }
.sample-content .note { display: block; margin-top: 0.2rem; font-size: 0.85rem; color: var(--text-muted); }

.sample-quiz { margin-bottom: 2rem; }
.sample-quiz h2 {
  font-size: 1.25rem;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.section-desc { margin: 0 0 1.5rem; color: var(--text-muted); font-size: 0.9rem; }

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
.btn-next { background: var(--hirono-blue); color: #fff; }
.btn-next:hover { background: var(--hirono-blue-light); }
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
.cta-after {
  margin: 0 0 1.25rem;
  font-size: 0.95rem;
  color: var(--text-muted);
}
.actions { display: flex; flex-direction: column; gap: 0.75rem; align-items: center; }
.btn-signup { background: var(--hirono-green); color: #fff; }
.btn-signup:hover { background: var(--hirono-green-light); }
.btn-learn { background: var(--hirono-blue); color: #fff; }
.btn-learn:hover { background: var(--hirono-blue-light); }
.btn-retry { background: #cbd5e1; color: var(--text-primary); }
.btn-retry:hover { background: #e2e8f0; }
</style>
