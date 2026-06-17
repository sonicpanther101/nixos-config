-- ── options.lua ──────────────────────────────────────────────────────────────
-- These are equivalent to VSCodium's settings.json — global editor behaviour.
-- `vim.opt.x = y` is the modern API. The old way was `vim.o.x = y` (still works).
-- ─────────────────────────────────────────────────────────────────────────────

local opt = vim.opt

-- ── Line numbers ─────────────────────────────────────────────────────────────
-- TIP: relative numbers are central to vim motions — `5j` jumps 5 lines down
-- because you can see the number 5 next to that line. Give it a week.
opt.number         = true   -- show absolute number on the cursor line
opt.relativenumber = true   -- show relative numbers everywhere else

-- ── Tabs & indentation ───────────────────────────────────────────────────────
opt.tabstop        = 4      -- a <Tab> character looks like 4 spaces
opt.softtabstop    = 4      -- pressing <Tab> inserts 4 spaces
opt.shiftwidth     = 4      -- >> and << indent by 4 spaces
opt.expandtab      = true   -- always insert spaces, never a real tab character
opt.smartindent    = true   -- auto-indent on new lines based on context

-- ── Search ───────────────────────────────────────────────────────────────────
opt.ignorecase     = true   -- /foo matches Foo, FOO, etc.
opt.smartcase      = true   -- /Foo only matches Foo (overrides ignorecase when uppercase used)
opt.hlsearch       = false  -- don't keep matches highlighted after search (annoying)
opt.incsearch      = true   -- highlight while you type the pattern

-- ── Appearance ───────────────────────────────────────────────────────────────
opt.termguicolors  = true   -- 24-bit colour — needed for catppuccin to look right
opt.cursorline     = true   -- highlight the line the cursor is on
opt.scrolloff      = 8      -- keep 8 lines above/below cursor when scrolling
opt.signcolumn     = 'yes'  -- always show the gutter (LSP diagnostics live here)
                            -- 'yes' stops the text jumping left/right as errors appear
opt.colorcolumn    = '120'  -- vertical ruler at 120 chars
opt.wrap           = false  -- don't wrap long lines (horizontal scroll instead)

-- ── Splits ───────────────────────────────────────────────────────────────────
-- TIP: use <C-w>v to vertical split, <C-w>s horizontal, <C-w>h/j/k/l to move
opt.splitbelow     = true   -- :split opens below current window
opt.splitright     = true   -- :vsplit opens to the right

-- ── Files & undo ─────────────────────────────────────────────────────────────
opt.swapfile       = false  -- no .swp files cluttering your repo
opt.backup         = false  -- no backup files either
opt.undofile       = true   -- persistent undo across sessions (survives reboot!)
opt.undodir        = vim.fn.stdpath('data') .. '/undo'  -- store undo history here

-- ── Performance ──────────────────────────────────────────────────────────────
opt.updatetime     = 250    -- faster CursorHold (used by LSP hover + gitsigns)
opt.timeoutlen     = 300    -- ms to wait for a key sequence (e.g. <leader>sf)

-- ── Completion ───────────────────────────────────────────────────────────────
opt.completeopt    = { 'menuone', 'noselect' }  -- don't auto-select completions

-- ── Clipboard ────────────────────────────────────────────────────────────────
-- TIP: without this, vim has its own clipboard separate from the system one.
-- With it, yank (y) and paste (p) use the Wayland clipboard directly.
opt.clipboard      = 'unnamedplus'

-- ── Mouse ────────────────────────────────────────────────────────────────────
opt.mouse          = 'a'    -- mouse support in all modes (useful while learning)

-- ── Misc ─────────────────────────────────────────────────────────────────────
opt.conceallevel   = 0      -- show backticks in markdown (not hidden)
opt.fileencoding   = 'utf-8'
opt.pumheight      = 10     -- max 10 items in the completion popup
opt.showmode       = false  -- lualine shows the mode, no need for the cmdline one

-- Create undo directory if it doesn't exist yet
vim.fn.mkdir(vim.fn.stdpath('data') .. '/undo', 'p')

-- ── Autosave (afterDelay equivalent) ────────────────────────────────────────
-- Mirrors VSCode's "files.autoSave": "afterDelay" — saves automatically
-- after you stop typing for a short period, but only for real files.

local autosave_delay = 1000  -- ms, matches VSCode's default 1000ms

vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
  pattern = '*',
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].buftype ~= '' then return end
    if not vim.bo[bufnr].modifiable then return end
    if vim.api.nvim_buf_get_name(bufnr) == '' then return end
    if not vim.bo[bufnr].modified then return end

    -- Debounce: cancel any pending save timer for this buffer
    local existing = vim.b[bufnr].autosave_timer
    if existing ~= nil then
      existing:stop()
      existing:close()
      vim.b[bufnr].autosave_timer = nil
    end

    local timer = vim.loop.new_timer()
    vim.b[bufnr].autosave_timer = timer

    if timer ~= nil then
      timer:start(autosave_delay, 0, function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd('silent! write')
            end)
          end
        end)
        if timer ~= nil then
          timer:stop()
          timer:close()
        end
      end)
    end
  end,
})

-- Transparent background — lets kitty's terminal opacity show through.
-- Without this, nvim renders its own solid background colour which doesn't
-- reach the kitty window edges (visible as a colour mismatch border).
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    local groups = {
      'Normal', 'NormalNC', 'NormalFloat',
      'SignColumn', 'StatusLine', 'StatusLineNC',
      'EndOfBuffer', 'LineNr', 'CursorLineNr',
      'FoldColumn', 'WinBar', 'WinBarNC',
    }
    for _, g in ipairs(groups) do
      vim.api.nvim_set_hl(0, g, { bg = 'none', ctermbg = 'none' })
    end
  end,
})
-- Fire immediately for the initial colorscheme load
vim.cmd('doautocmd ColorScheme')
