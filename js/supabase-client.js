(function () {
  const cfg = window.SITE_CONFIG || {};
  const ready = !!(window.supabase && cfg.supabaseUrl && cfg.supabaseAnonKey &&
    !cfg.supabaseUrl.includes('YOUR-PROJECT-REF') && !cfg.supabaseAnonKey.includes('YOUR_SUPABASE'));
  window.supabaseClientReady = ready;
  window.supabaseClient = ready ? window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey) : null;
})();
