-- Options are automatically loaded before lazy.nvim startup
-- Add any additional options here

----------------
--- SETTINGS ---
----------------

-- disable netrw at the very start of our init.lua, because we use oil.nvim
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Disable Perl Provider for mason.nvim
vim.g.loaded_perl_provider = 0

vim.opt.termguicolors = true -- Enable 24-bit RGB colors
vim.opt.number = true -- Show line numbers
vim.opt.showmatch = true -- Highlight matching parenthesis
vim.opt.splitright = true -- Split windows right to the current windows
vim.opt.splitbelow = true -- Split windows below to the current windows
vim.opt.autowrite = true -- Automatically save before :next, :make etc.
-- vim.opt.autochdir = true -- Change CWD when I open a file

vim.opt.mouse = "a" -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Copy/paste to system clipboard
vim.opt.swapfile = false -- Don't use swapfile
vim.opt.undofile = true -- Persistent undo history
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.signcolumn = "yes" -- Always show sign column to prevent layout shifts
vim.opt.updatetime = 250 -- Faster CursorHold events (default is 4000ms)
vim.opt.ignorecase = true -- Search case insensitive...
vim.opt.smartcase = true -- ... but not if begins with upper case
vim.opt.completeopt = "menuone,noinsert,noselect" -- Autocomplete options
vim.opt.textwidth = 120
vim.opt.colorcolumn = "80"
vim.opt.relativenumber = false

-- Indent Settings
-- I'm in the Spaces camp (sorry Tabs folks), so I'm using a combination of
-- settings to insert spaces all the time.
vim.opt.expandtab = true -- expand tabs into spaces
vim.opt.shiftwidth = 2 -- number of spaces to use for each step of indent.
vim.opt.tabstop = 2 -- number of spaces a TAB counts for
vim.opt.autoindent = true -- copy indent from current line when starting a new line
vim.opt.wrap = true

-- Register MDX filetype before plugins load
vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})
vim.treesitter.language.register("markdown", "mdx")
