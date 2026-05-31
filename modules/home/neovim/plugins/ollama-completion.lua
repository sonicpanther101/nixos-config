-- ── plugins/ollama-completion.lua ────────────────────────────────────────────
-- cmp-ai adds ollama as a source to the nvim-cmp pipeline you already have.
-- It calls your local ollama (127.0.0.1:11434) with qwen2.5-coder:14b —
-- the same model you already have loaded in services.nix.
--
-- It appears in the completion menu as [AI].
-- No ghost text — completions appear in the cmp popup like LSP results do.
-- ─────────────────────────────────────────────────────────────────────────────

require('cmp_ai.config'):setup({
  max_lines      = 60,      -- lines of context sent to the model (more = slower)
  provider       = 'Ollama',
  provider_options = {
    model = 'qwen2.5-coder:14b',
    -- ollama's default address — matches your services.nix setup
    url   = 'http://127.0.0.1:11434/api/generate',
    options = {
      temperature   = 0.1,  -- low = more deterministic completions
      num_predict   = 100,  -- max tokens in completion
    },
  },
  -- Only trigger on explicit <C-Space>, not every keystroke
  -- (qwen2.5-coder is fast but not instantaneous on CPU)
  run_on_every_keystroke = true,
  notify         = false,   -- don't show "waiting for AI..." messages
  ignored_file_types = {
    'help', 'TelescopePrompt', 'neo-tree', 'oil',
  },
})