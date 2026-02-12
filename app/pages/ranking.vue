<script setup lang="ts">
const supabase = useSupabaseClient()

type ScoreRow = {
  id: string
  email: string
  score: number
  total_questions: number
  created_at: string
}

const ranking = ref<ScoreRow[]>([])
const loading = ref(true)
const error = ref('')

async function fetchRanking () {
  loading.value = true
  error.value = ''
  try {
    const { data, error: e } = await supabase
      .from('quiz_scores')
      .select('id, email, score, total_questions, created_at')
      .order('score', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(100)

    if (e) throw e
    ranking.value = (data ?? []) as ScoreRow[]
  } catch (e) {
    error.value = 'ランキングの取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchRanking()
})

function formatDate (iso: string) {
  try {
    return new Date(iso).toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  } catch {
    return iso
  }
}
</script>

<template>
  <div class="page-ranking">
    <header class="page-header">
      <h1>ランキング</h1>
      <p class="page-desc">クイズのスコア上位です。ログインしてクイズに挑戦すると記録されます。</p>
      <button
        type="button"
        class="btn-reload"
        :disabled="loading"
        @click="fetchRanking"
      >
        {{ loading ? '読み込み中…' : '最新のデータを読み込む' }}
      </button>
    </header>

    <main class="ranking-content">
      <div v-if="loading" class="loading">読み込み中…</div>
      <p v-else-if="error" class="error-msg">{{ error }}</p>

      <div v-else class="ranking-box">
        <table class="ranking-table">
          <thead>
            <tr>
              <th class="col-rank">順位</th>
              <th class="col-email">メール</th>
              <th class="col-score">スコア</th>
              <th class="col-date">日付</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(row, index) in ranking"
              :key="row.id"
              :class="{ 'row-top3': index < 3 }"
            >
              <td class="col-rank">
                <span v-if="index === 0" class="medal gold">1</span>
                <span v-else-if="index === 1" class="medal silver">2</span>
                <span v-else-if="index === 2" class="medal bronze">3</span>
                <span v-else>{{ index + 1 }}</span>
              </td>
              <td class="col-email">{{ row.email }}</td>
              <td class="col-score">{{ row.score }} / {{ row.total_questions }}</td>
              <td class="col-date">{{ formatDate(row.created_at) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-if="!ranking.length" class="no-data">まだスコアがありません。ログインしてクイズに挑戦しよう！</p>
      </div>

      <div class="ranking-actions">
        <NuxtLink to="/" class="btn-back">ホームに戻る</NuxtLink>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page-ranking { padding-bottom: 3rem; }

.page-header {
  text-align: center;
  padding: 2.5rem 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.page-header h1 {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  color: var(--text-primary);
}
.page-desc {
  margin: 0 0 0.75rem;
  color: var(--text-muted);
  font-size: 0.95rem;
  max-width: 480px;
  margin-left: auto;
  margin-right: auto;
}
.btn-reload {
  padding: 0.4rem 0.75rem;
  border-radius: 8px;
  font-size: 0.85rem;
  border: 1px solid var(--hirono-blue);
  background: transparent;
  color: var(--hirono-blue);
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}
.btn-reload:hover:not(:disabled) { background: var(--hirono-blue-dim); color: var(--hirono-blue); }
.btn-reload:disabled { opacity: 0.7; cursor: not-allowed; }

.ranking-content {
  max-width: 720px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.loading, .error-msg {
  text-align: center;
  color: var(--text-muted);
  padding: 2rem;
}
.error-msg { color: #c53030; }

.ranking-box {
  background: var(--bg-card);
  border-radius: 12px;
  border: 1px solid var(--border-subtle);
  overflow: hidden;
  margin-bottom: 1.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.ranking-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.95rem;
}
.ranking-table th {
  text-align: left;
  padding: 0.75rem 1rem;
  background: #f8fafc;
  color: var(--text-muted);
  font-weight: 600;
  font-size: 0.85rem;
  border-bottom: 1px solid var(--border-subtle);
}
.ranking-table td {
  padding: 0.75rem 1rem;
  border-top: 1px solid var(--border-subtle);
  color: var(--text-primary);
}
.ranking-table tr.row-top3 { background: var(--hirono-blue-dim); }
.ranking-table tr.row-top3:nth-child(2) { background: var(--hirono-green-dim); }
.ranking-table tr:hover { background: #f8fafc; }

.col-rank { width: 72px; text-align: center; }
.col-email { min-width: 140px; }
.col-score { width: 100px; text-align: center; }
.col-date { width: 100px; color: var(--text-muted); font-size: 0.9rem; }

.medal {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  font-weight: 700;
  font-size: 0.9rem;
}
.medal.gold { background: linear-gradient(135deg, var(--hirono-green-light), var(--hirono-green)); color: #fff; }
.medal.silver { background: linear-gradient(135deg, var(--hirono-blue-light), var(--hirono-blue)); color: #fff; }
.medal.bronze { background: linear-gradient(135deg, #94a3b8, #64748b); color: #fff; }

.no-data {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
  margin: 0;
}

.ranking-actions { text-align: center; }
.btn-back {
  display: inline-block;
  padding: 0.6rem 1.25rem;
  border-radius: 8px;
  background: var(--hirono-blue);
  color: #fff;
  text-decoration: none;
  font-weight: 600;
  font-size: 0.95rem;
  transition: background 0.2s;
}
.btn-back:hover { background: var(--hirono-blue-light); color: #fff; }
</style>
