-- Keymaps are automatically loaded on the VeryLazy event
-- Add any additional keymaps here

-- Fast saving
vim.keymap.set("n", "<Leader>s", ":write!<CR>")
vim.keymap.set("n", "<Leader>q", ":q!<CR>", { silent = true })

-- Some useful quickfix shortcuts for quickfix
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-m>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>a", "<cmd>cclose<CR>")

-- Visual linewise up and down
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Exit on jj and jk
vim.keymap.set("i", "jj", "<ESC>")
vim.keymap.set("i", "jk", "<ESC>")

-- Remove search highlight
vim.keymap.set("n", "<Leader><space>", ":nohlsearch<CR>")

-- Don't jump forward if I highlight and search for a word
local function stay_star()
  local sview = vim.fn.winsaveview()
  local args = string.format("keepjumps keeppatterns execute %q", "sil normal! *")
  vim.api.nvim_command(args)
  vim.fn.winrestview(sview)
end
vim.keymap.set("n", "*", stay_star, { noremap = true, silent = true })

-- Search mappings: These will make it so that going to the next one in a
-- search will center on the line it's found in.
vim.keymap.set("n", "n", "nzzzv", { noremap = true })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true })

-- We don't need this keymap, but here we are. If I do a ctrl-v and select
-- lines vertically, insert stuff, they get lost for all lines if we use
-- ctrl-c, but not if we use ESC. So just let's assume Ctrl-c is ESC.
vim.keymap.set("i", "<C-c>", "<ESC>")

-- If I visually select words and paste from clipboard, don't replace my
-- clipboard with the selected word, instead keep my old word in the
-- clipboard
vim.keymap.set("x", "p", '"_dP')

-- rename the word under the cursor
vim.keymap.set("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Visual linewise up and down by default (and use gj gk to go quicker)
vim.keymap.set("n", "<Up>", "gk")
vim.keymap.set("n", "<Down>", "gj")

-- Terminal
-- Close terminal window, even if we are in insert mode
vim.keymap.set("t", "<leader>q", "<C-\\><C-n>:q<cr>")

-- switch to normal mode with esc
vim.keymap.set("t", "<ESC>", "<C-\\><C-n>")

-- Open terminal in vertical and horizontal split
vim.keymap.set("n", "<leader>tv", "<cmd>vnew term://fish<CR>", { noremap = true })
vim.keymap.set("n", "<leader>ts", "<cmd>split term://fish<CR>", { noremap = true })

-- Open terminal in vertical and horizontal split, inside the terminal
vim.keymap.set("t", "<leader>tv", "<c-w><cmd>vnew term://fish<CR>", { noremap = true })
vim.keymap.set("t", "<leader>ts", "<c-w><cmd>split term://fish<CR>", { noremap = true })

-- mappings to move out from terminal to other views
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- we don't use netrw (because of oil.nvim), hence re-implement gx to open
-- links in browser
vim.keymap.set("n", "gx", function()
  vim.ui.open(vim.fn.expand("<cfile>"))
end, { desc = "Open file/URL under cursor" })

-- git.nvim
vim.keymap.set("n", "<leader>gb", '<CMD>lua require("git.blame").blame()<CR>')
vim.keymap.set("n", "<leader>go", "<CMD>lua require('git.browse').open(false)<CR>")
vim.keymap.set("x", "<leader>go", ":<C-u> lua require('git.browse').open(true)<CR>")

-- File explorer (oil.nvim)
-- Note: `-` opens parent dir (set in init.lua), these are extras
vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { noremap = true, desc = "Open file explorer" })

-- Copy current filepath to system clipboard (git-relative, fallback to absolute)
vim.keymap.set("n", "<leader>yp", function()
  local git_prefix = vim.fn.system("git rev-parse --show-prefix"):gsub("\n", "")
  local path
  if vim.v.shell_error == 0 then
    path = git_prefix .. vim.fn.expand("%")
  else
    path = vim.fn.expand("%:p")
  end
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { silent = true, desc = "Copy filepath to clipboard" })

-- Go to next tab
vim.keymap.set("n", "<leader>]", ":tabnext<CR>", { noremap = true, silent = true, desc = "Next Tab" })

-- Go to previous tab
vim.keymap.set("n", "<leader>[", ":tabprevious<CR>", { noremap = true, silent = true, desc = "Previous Tab" })
