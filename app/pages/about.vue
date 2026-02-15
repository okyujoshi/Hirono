<script setup lang="ts">
// このサイトについて — 学生向け / 社会人向けで文言を切り替え
type Identity = 'teen' | 'adult'
const identity = ref<Identity>('teen')

function setIdentity (value: Identity) {
  identity.value = value
}
</script>

<template>
  <div class="page-about">
    <header class="about-hero">
      <h1>このサイトについて</h1>
      <p class="about-lead">
        {{ identity === 'teen' ? 'プログラミング好きの君へ' : '社会人の方へ' }}
      </p>
      <div class="identity-tabs" role="tablist" aria-label="読者タイプ">
        <button
          type="button"
          class="tab"
          :class="{ active: identity === 'teen' }"
          role="tab"
          :aria-selected="identity === 'teen'"
          @click="setIdentity('teen')"
        >
          学生向け
        </button>
        <button
          type="button"
          class="tab"
          :class="{ active: identity === 'adult' }"
          role="tab"
          :aria-selected="identity === 'adult'"
          @click="setIdentity('adult')"
        >
          社会人向け
        </button>
      </div>
    </header>

    <main class="about-content">
      <!-- 学生向け -->
      <template v-if="identity === 'teen'">
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/hero.png" alt="プログラミングと英語" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            日本語ネイティブの君は、世界でいちばん難しい言語をあやつってる。それだけでもすごいよね。
          </p>
          <p class="about-text">
            英語はちょっと…って思ってるけど、プログラミングは好き。そんな子、めちゃくちゃ多いと思う。
          </p>
        </section>
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/code-words.png" alt="コードの中の英単語" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            今はAIがコードを書いてくれる時代だけど、プログラミングが生まれたのは西洋。0と1の考え方から始まって、テキストや色を表すのにアルファベットが使われるようになった。もしプログラミングの元祖が日本語だったら、世界にここまで広まってなかったかも。
          </p>
          <p class="about-text">
            君が毎日触ってるタグやコード、ほとんどが英単語の略だよね。それだけで<strong>200語以上</strong>ある。
          </p>
          <p class="about-text">
            その200語を「なんとなく意味わかる」じゃなく、<strong>使い倒す</strong>くらいわかれば、日常会話はだいたいこなせる。コードは、君が端末と話すための立派な外国語だから。
          </p>
          <p class="about-text about-insight">
            受験でも、将来の仕事でも、この「コードの英語」がそのまま土台になる。今のうちに慣れておくと、絶対お得。
          </p>
        </section>
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/listen-speak.png" alt="聴いて、真似して、喋れるように" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            まずは<strong>音声</strong>で単語や例文を聴いてみて。恥ずかしがらずに、慣れてきたらブツブツ、自分にしか聞こえないくらいの大きさでいいから発音を真似してみて。いつの間にか、喋れるようになる。
          </p>
        </section>
        <section class="about-block about-why-here">
          <h2 class="about-subtitle">このサイトでできること</h2>
          <ul class="about-list">
            <li><strong>今日の単語</strong> — 同じ語源の単語を1日1セット、意味と例文で覚える</li>
            <li><strong>穴埋めクイズ</strong> — 例文の空欄に単語を入れて定着させる</li>
            <li><strong>音声</strong> — 単語・例文を聴いて、真似して発音できる</li>
          </ul>
          <p class="about-text about-low-barrier">
            登録しなくても<strong>学習ページ</strong>で今日の単語とクイズを試せる。まずは1語から、5分だけでもOK。
          </p>
        </section>
        <section class="about-block about-cta">
          <p class="about-text about-start">さあ、始めよう！</p>
          <NuxtLink to="/learn" class="btn-start">学習ページへ</NuxtLink>
        </section>
      </template>

      <!-- 社会人向け -->
      <template v-else>
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/hero-adult.png" alt="社会人とプログラミング・英語" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            日本語ネイティブの方は、世界でいちばん難しいと言われる日本語を操っている、とても頭のよい方です。
          </p>
          <p class="about-text">
            これまで英語を体系的に学ぶのを避けてきたけれど、やはり必要だと感じている。そんな方も多いのではないでしょうか。仕事でコードには触れるし、プログラミングの世界は好き。ただ、英語は腰を据えて勉強してこなかった、という方へ。
          </p>
        </section>
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/code-words.png" alt="コードの中の英単語" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            令和の今、AIがスクリプトを書いてくれる時代ですが、プログラミングが生まれたのは西洋です。0と1の概念から始まり、テキストや色を表すにはアルファベットが使われるようになりました。もしプログラミングの元祖が日本語だったら、ここまで世界に普及しなかったかもしれません。
          </p>
          <p class="about-text">
            日頃から触っているタグやコードは、ほとんどが英単語の略です。それだけで<strong>200語以上</strong>あります。
          </p>
          <p class="about-text">
            その200語を「なんとなく意味はわかる」ではなく、<strong>使いこなせる</strong>レベルにすれば、日常会話はほぼこなせます。あなたが毎日打ち込んでるコードは、端末と対話するための立派な外国語だからです。そう、すでにあなたはバイリンガルなんです。
          </p>
          <p class="about-text about-insight">
            この200語が身につくと、英語のドキュメントやエラーメッセージ、海外の記事やカンファレンス動画が「なんとなく」から「はっきり」に変わります。仕事の選択肢も広がります。
          </p>
        </section>
        <section class="about-block">
          <div class="about-image-wrap">
            <img src="/about/listen-speak.png" alt="聴いて、真似して、話せるように" class="about-img" width="640" height="360" loading="lazy" />
          </div>
          <p class="about-text">
            まずは<strong>音声</strong>で単語や例文を聴いてください。恥ずかしがらず、慣れてきたら小声でいいので発音を真似してみてください。いつの間にか、話せるようになります。
          </p>
        </section>
        <section class="about-block about-why-here">
          <h2 class="about-subtitle">このサイトでできること</h2>
          <ul class="about-list">
            <li><strong>今日の単語</strong> — 同じ語源の単語を1日1セット、意味と例文で覚える</li>
            <li><strong>穴埋めクイズ</strong> — 例文の空欄に単語を入れて定着させる</li>
            <li><strong>音声</strong> — 単語・例文を聴いて、真似して発音できる</li>
          </ul>
          <p class="about-text about-low-barrier">
            登録しなくても<strong>学習ページ</strong>で今日の単語とクイズを試せます。まずは1語から、5分だけでも大丈夫です。
          </p>
        </section>
        <section class="about-block about-cta">
          <p class="about-text about-start">さあ、始めましょう。</p>
          <NuxtLink to="/learn" class="btn-start">学習ページへ</NuxtLink>
        </section>
      </template>

      <section class="about-block about-meta">
        <p class="about-text small">
          このサイトは無料です。これからコンテンツを増やして充実できたら、寄付をいただけると幸いです。
        </p>
        <p class="about-signature">（この文章はAIではなく、管理人が書きました）</p>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page-about { padding-bottom: 3rem; }

.about-hero {
  text-align: center;
  padding: 2rem 1.5rem;
  border-bottom: 1px solid var(--border-subtle);
}
.about-hero h1 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0 0 0.35rem;
  color: var(--text-primary);
}
.about-lead {
  margin: 0 0 1rem;
  font-size: 1rem;
  color: var(--hirono-blue);
  font-weight: 600;
}

.identity-tabs {
  display: flex;
  gap: 0.5rem;
  justify-content: center;
  flex-wrap: wrap;
}
.identity-tabs .tab {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  border: 1px solid var(--border-subtle);
  background: var(--bg-card);
  color: var(--text-muted);
  cursor: pointer;
  transition: background 0.2s, color 0.2s, border-color 0.2s;
}
.identity-tabs .tab:hover {
  color: var(--text-primary);
  border-color: var(--hirono-blue-light);
  background: var(--hirono-blue-dim);
}
.identity-tabs .tab.active {
  background: var(--hirono-blue);
  color: #fff;
  border-color: var(--hirono-blue);
}

.about-content {
  max-width: 640px;
  margin: 0 auto;
  padding: 1.5rem 1.25rem;
}

.about-block {
  margin-bottom: 2rem;
}
.about-image-wrap {
  border-radius: 12px;
  overflow: hidden;
  margin-bottom: 1rem;
  border: 1px solid var(--border-subtle);
  background: var(--bg-card);
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  min-height: 120px;
}
.about-img {
  width: 100%;
  height: auto;
  display: block;
  object-fit: cover;
}
.about-text {
  margin: 0 0 1rem;
  font-size: 0.95rem;
  line-height: 1.75;
  color: var(--text-primary);
}
.about-text:last-child { margin-bottom: 0; }
.about-text strong { color: var(--hirono-blue); }

.about-insight {
  padding: 0.75rem 1rem;
  background: var(--hirono-blue-dim);
  border-left: 4px solid var(--hirono-blue);
  border-radius: 0 8px 8px 0;
  margin-top: 1rem !important;
}

.about-why-here {
  padding: 1.25rem;
  background: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
}
.about-subtitle {
  font-size: 1rem;
  font-weight: 700;
  margin: 0 0 0.75rem;
  color: var(--text-primary);
}
.about-list {
  margin: 0 0 1rem;
  padding-left: 1.25rem;
  font-size: 0.9rem;
  line-height: 1.7;
  color: var(--text-primary);
}
.about-list li { margin-bottom: 0.35rem; }
.about-list strong { color: var(--hirono-blue); }
.about-low-barrier {
  margin-bottom: 0 !important;
  font-size: 0.9rem;
  color: var(--text-muted);
}

.about-cta {
  text-align: center;
  padding: 1.5rem;
  background: linear-gradient(135deg, var(--hirono-blue-dim) 0%, var(--hirono-green-dim) 100%);
  border-radius: 12px;
  border: 1px solid var(--border-subtle);
}
.about-start {
  font-size: 1.15rem;
  font-weight: 700;
  margin-bottom: 1rem !important;
  color: var(--text-primary);
}
.btn-start {
  display: inline-block;
  padding: 0.65rem 1.5rem;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 600;
  background: var(--hirono-blue);
  color: #fff;
  text-decoration: none;
  transition: background 0.2s, opacity 0.2s;
}
.btn-start:hover { background: var(--hirono-blue-light); opacity: 0.95; }

.about-meta {
  padding-top: 0.5rem;
  border-top: 1px dashed var(--border-subtle);
}
.about-text.small { font-size: 0.9rem; color: var(--text-muted); }
.about-signature {
  margin: 1rem 0 0;
  font-size: 0.85rem;
  color: var(--text-muted);
  font-style: italic;
}
</style>
