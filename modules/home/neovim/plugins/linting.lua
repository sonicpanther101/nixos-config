-- ── plugins/linting.lua ──────────────────────────────────────────────────────
-- nvim-lint runs linters as external processes and feeds results into
-- vim.diagnostic, so they appear alongside LSP diagnostics seamlessly.
--
-- Pylint is disabled by default — enable it with :PylintEnable or toggle
-- with :PylintToggle. State persists for the session only.
--
-- TIP: pylint is slower than pyright (which is always on). Use this when
-- you want the extra checks (convention, refactor, etc.) that pyright skips.
-- ─────────────────────────────────────────────────────────────────────────────

local ok, lint = pcall(require, 'lint')
if not ok then
  vim.notify('nvim-lint not found — skipping linting setup', vim.log.levels.WARN)
  return
end

-- ── State ─────────────────────────────────────────────────────────────────────
local pylint_enabled = false

-- ── Configure linters ─────────────────────────────────────────────────────────
lint.linters_by_ft = {
  -- Empty by default; pylint is added/removed dynamically below
}

-- ── Run linting ───────────────────────────────────────────────────────────────
local function run_lint()
  -- Only lint if the buffer has a real file path
  if vim.api.nvim_buf_get_name(0) == '' then return end
  if vim.bo.buftype ~= '' then return end
  lint.try_lint()
end

-- ── Toggle helpers ────────────────────────────────────────────────────────────
local function set_pylint(enabled)
  pylint_enabled = enabled

  if enabled then
    lint.linters_by_ft.python = { 'pylint' }
    vim.notify('Pylint enabled', vim.log.levels.INFO)
    -- Immediately lint the current buffer if it's a Python file
    if vim.bo.filetype == 'python' then run_lint() end
  else
    lint.linters_by_ft.python = {}
    -- Clear pylint diagnostics from all buffers
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.reset(vim.api.nvim_create_namespace('nvim-lint'), bufnr)
      end
    end
    vim.notify('Pylint disabled', vim.log.levels.INFO)
  end
end

-- ── Auto-lint on save / enter (only fires when pylint is on) ─────────────────
vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
  callback = function()
    if pylint_enabled then run_lint() end
  end,
})

-- ── User commands ─────────────────────────────────────────────────────────────
vim.api.nvim_create_user_command('PylintEnable',  function() set_pylint(true)  end, { desc = 'Enable pylint diagnostics' })
vim.api.nvim_create_user_command('PylintDisable', function() set_pylint(false) end, { desc = 'Disable pylint diagnostics' })
vim.api.nvim_create_user_command('PylintToggle',  function() set_pylint(not pylint_enabled) end, { desc = 'Toggle pylint diagnostics' })
vim.api.nvim_create_user_command('PylintStatus',  function()
  vim.notify('Pylint is ' .. (pylint_enabled and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = 'Show pylint status' })
