// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: ['@nuxtjs/supabase'],
  supabase: {
    redirect: false
  },
  runtimeConfig: {
    public: {
      /** 管理画面にアクセスできる管理者メール（変更時は NUXT_PUBLIC_ADMIN_EMAIL で上書き可） */
      adminEmail: 'hutz@nifty.com'
    }
  }
})
