-- ── plugins/ollama-completion.lua ────────────────────────────────────────────
-- cmp-ai adds ollama as a cmp source. Uses qwen2.5-coder:14b which is already
-- loaded in your services.nix. Shows up as [AI] in the completion menu.
-- ─────────────────────────────────────────────────────────────────────────────

local ok, cmp_ai = pcall(require, 'cmp_ai.config')
if not ok then
  vim.notify('cmp-ai not found', vim.log.levels.WARN)
  return
end

cmp_ai:setup({
  max_lines = 2,
  provider  = 'Ollama',
  provider_options = {
    model = 'qwen2.5-coder:14b',
    url   = 'http://127.0.0.1:11434/api/generate',
    options = {
      temperature = 0.1,
      num_predict = 100,
    },
  },
  run_on_every_keystroke = false,
  notify = false,
  ignored_file_types = { 'help', 'TelescopePrompt' },
})
