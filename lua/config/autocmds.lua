-- Autocmds are automatically loaded on the VeryLazy event
-- Add any additional autocmds here

-- automatically switch to insert mode when entering a Term buffer
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("openTermInsert", {}),
  callback = function(args)
    -- we don't use vim.startswith() and look for test:// because of vim-test
    -- vim-test starts tests in a terminal, which we want to keep in normal mode
    if vim.endswith(vim.api.nvim_buf_get_name(args.buf), "fish") then
      vim.cmd("startinsert")
    end
  end,
})

-- Open help window in a vertical split to the right.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("help_window_right", {}),
  pattern = { "*.txt" },
  callback = function()
    if vim.o.filetype == "help" then
      vim.cmd.wincmd("L")
    end
  end,
})

-- old habits for git commands
vim.api.nvim_create_user_command("GBrowse", function()
  require("git.browse").open(true)
end, {
  range = true,
  bang = true,
  nargs = "*",
})

vim.api.nvim_create_user_command("GBlame", function()
  require("git.blame").blame()
end, {})
vim.api.nvim_create_user_command("Gblame", function()
  require("git.blame").blame()
end, {})

-- Go uses gofmt, which uses tabs for indentation and spaces for alignment.
-- Hence override our indentation rules.
vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("setIndent", { clear = true }),
  pattern = { "go" },
  command = "setlocal noexpandtab tabstop=4 shiftwidth=4",
})

-- Update configuration for Markdown/MDX — soft wrap, no hard line breaks, spellcheck
vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("setMarkdownConfig", { clear = true }),
  pattern = { "markdown", "mdx" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Run gofmt/gofmpt, import packages automatically on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("setGoFormatting", { clear = true }),
  pattern = "*.go",
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })
    local encoding = (clients[1] and clients[1].offset_encoding) or "utf-16"
    local params = vim.lsp.util.make_range_params(0, encoding)
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 2000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, encoding)
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end

    vim.lsp.buf.format()
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rb",
  callback = function()
    vim.lsp.buf.format()
  end,
})

-- automatically resize all vim buffers if I resize the terminal window
vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "wincmd =",
})

-- https://github.com/neovim/neovim/issues/21771
local exitgroup = vim.api.nvim_create_augroup("setDir", { clear = true })
vim.api.nvim_create_autocmd("DirChanged", {
  group = exitgroup,
  pattern = { "*" },
  command = [[call chansend(v:stderr, printf("\033]7;file://%s\033\\", v:event.cwd))]],
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = exitgroup,
  pattern = { "*" },
  command = [[call chansend(v:stderr, "\033]7;\033\\")]],
})

-- put quickfix window always to the bottom
local qfgroup = vim.api.nvim_create_augroup("changeQuickfix", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  group = qfgroup,
  command = "wincmd J",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  group = qfgroup,
  command = "setlocal wrap",
})

-- highlight yanked text for 200ms using the "Visual" highlight group
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
  end,
})
