-- bootstrap lazy.nvim, LazyVim and your plugins
-- This comes first, because we have mappings that depend on leader
-- With a map leader it's possible to do extra key combinations
-- i.e: <leader>w saves the current file
vim.g.mapleader = ","

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Always keep a black background
vim.o.background = "dark"

-- run :GoBuild or :GoTestCompile based on the go file
local function build_go_files()
  if vim.endswith(vim.api.nvim_buf_get_name(0), "_test.go") then
    vim.cmd("GoTestCompile")
  else
    vim.cmd("GoBuild")
  end
end

local slow_format_filetypes = {}

-- Plugins
require("lazy").setup({
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
    end,
  },
  -- colorscheme
  {
    "jasonlong/poimandres.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "storm",
    },
    config = function()
      vim.cmd([[colorscheme poimandres]])
    end,
  },
  {
    "echasnovski/mini.surround",
    version = false,
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    },
  },

  -- LSP
  {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "auto" },
        sections = {
          lualine_c = {
            {
              "filename",
              file_status = true, -- displays file status (readonly status, modified status)
              path = 2, -- 0 = just filename, 1 = relative path, 2 = absolute path
            },
          },
        },
      })
    end,
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = function(bufnr)
        if slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        local function on_format(err)
          if err and err:match("timeout$") then
            slow_format_filetypes[vim.bo[bufnr].filetype] = true
          end
        end

        return { timeout_ms = 200, lsp_fallback = true }, on_format
      end,

      format_after_save = function(bufnr)
        if not slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return { lsp_fallback = true }
      end,

      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        ruby = { "rubocop" },
        go = { "gofumpt", "gofmt" },
        ["javascript"] = { "prettier" },
        ["javascriptreact"] = { "prettier", "eslint" },
        ["typescript"] = { "prettier", "eslint" },
        ["typescriptreact"] = { "prettier", "eslint" },
        ["vue"] = { "prettier" },
        ["css"] = { "prettier" },
        ["scss"] = { "prettier" },
        ["less"] = { "prettier" },
        ["html"] = { "prettier" },
        ["json"] = { "prettier" },
        ["jsonc"] = { "prettier" },
        ["yaml"] = { "prettier" },
        ["markdown"] = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
        ["graphql"] = { "prettier" },
        ["handlebars"] = { "prettier" },
      },
    },
  },

  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
  },

  -- vim-go setup
  {
    "fatih/vim-go",
    config = function()
      -- we disable most of these features because treesitter and nvim-lsp
      -- take care of it
      vim.g["go_gopls_enabled"] = 0
      vim.g["go_code_completion_enabled"] = 0
      vim.g["go_fmt_autosave"] = 0
      vim.g["go_imports_autosave"] = 0
      vim.g["go_mod_fmt_autosave"] = 0
      vim.g["go_doc_keywordprg_enabled"] = 0
      vim.g["go_def_mapping_enabled"] = 0
      vim.g["go_textobj_enabled"] = 0
      vim.g["go_list_type"] = "quickfix"
    end,
  },

  -- search selection via *
  { "bronson/vim-visual-star-search" },

  -- testing framework
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>tn", ":TestNearest --verbose<CR>", { noremap = true, silent = true }, desc = "Test Nearest" },
      { "<leader>tf", ":TestFile --verbose<CR>", { noremap = true, silent = true }, desc = "Test File" },
      { "<leader>ta", ":TestSuite --verbose<CR>", { noremap = true, silent = true }, desc = "Test Suite" },
      { "<leader>tl", ":TestLast --verbose<CR>", { noremap = true, silent = true }, desc = "Test Last" },
    },
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#start_normal"] = "1"
    end,
  },

  {
    "dinhhuy258/git.nvim",
    config = function()
      require("git").setup()
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- copilot
  {
    "github/copilot.vim",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""

      vim.keymap.set("i", "<C-L>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
      })
    end,
  },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("copilot").setup({})
  --   end,
  -- },
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   config = function()
  --     require("copilot_cmp").setup()
  --   end,
  -- },

  -- file explorer
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        filters = {
          dotfiles = true,
        },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")

          local function opts(desc)
            return {
              desc = "nvim-tree: " .. desc,
              buffer = bufnr,
              noremap = true,
              silent = true,
              nowait = true,
            }
          end

          api.config.mappings.default_on_attach(bufnr)

          vim.keymap.set("n", "s", api.node.open.vertical, opts("Open: Vertical Split"))
          vim.keymap.set("n", "i", api.node.open.horizontal, opts("Open: Horizontal Split"))
          vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts("Up"))
        end,
      })
    end,
  },

  {
    "AndrewRadev/splitjoin.vim",
  },

  -- fzf extension for telescope with better speed
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },

  { "nvim-telescope/telescope-ui-select.nvim" },

  -- fuzzy finder framework
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("telescope").setup({
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case" the default case_mode is "smart_case"
          },
        },
      })

      -- To get ui-select loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require("telescope").load_extension("ui-select")

      -- To get fzf loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require("telescope").load_extension("fzf")
    end,
  },
  {
    "jremmen/vim-ripgrep",
  },
  { "airblade/vim-rooter" },
  {
    "mileszs/ack.vim",
    config = function()
      vim.g["ackprg"] = "ag --vimgrep"
    end,
  },

  -- save my last cursor position
  {
    "ethanholz/nvim-lastplace",
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
        lastplace_open_folds = true,
      })
    end,
  },

  -- Alternate between files, such as foo.go and foo_test.go
  {
    "rgroli/other.nvim",
    config = function()
      require("other-nvim").setup({
        mappings = {
          "rails", --builtin mapping
          "livewire",
          {
            pattern = "(.*).go$",
            target = "%1_test.go",
            context = "test",
          },
          {
            pattern = "(.*)_test.go$",
            target = "%1.go",
            context = "file",
          },
        },

        showMissingFiles = false,
      })

      vim.api.nvim_create_user_command("A", function(opts)
        require("other-nvim").open(opts.fargs[1])
      end, { nargs = "*" })

      vim.api.nvim_create_user_command("AV", function(opts)
        require("other-nvim").openVSplit(opts.fargs[1])
      end, { nargs = "*" })

      vim.api.nvim_create_user_command("AS", function(opts)
        require("other-nvim").openSplit(opts.fargs[1])
      end, { nargs = "*" })

      vim.api.nvim_create_user_command("AT", function(opts)
        require("other-nvim").openTabNew(opts.fargs[1])
      end, { nargs = "*" })

      vim.api.nvim_set_keymap("n", "<leader>ll", "<cmd>:Other<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>lh", "<cmd>:OtherSplit<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>lv", "<cmd>:OtherVSplit<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>lc", "<cmd>:OtherClear<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>ln", "<cmd>:OtherTabNew<CR>", { noremap = true, silent = true })

      -- Context specific bindings
      vim.api.nvim_set_keymap("n", "<leader>lt", "<cmd>:Other test<CR>", { noremap = true, silent = true })
    end,
  },

  -- markdown
  {
    "iamcco/markdown-preview.nvim",
    dependencies = {
      "zhaozg/vim-diagram",
      "aklt/plantuml-syntax",
    },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    ft = "markdown",
    cmd = { "MarkdownPreview" },
  },

  {
    "folke/neodev.nvim",
    config = function()
      require("neodev").setup()
    end,
  },

  -- lsp-config
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup()
      local util = require("lspconfig/util")

      local capabilities = require("cmp_nvim_lsp").default_capabilities(util.capabilities)
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      require("lspconfig").gopls.setup({
        capabilities = capabilities,
        flags = { debounce_text_changes = 200 },
        settings = {
          gopls = {
            usePlaceholders = true,
            gofumpt = true,
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            experimentalPostfixCompletions = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-node_modules" },
            semanticTokens = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      require("lspconfig").solargraph.setup({
        capabilities = capabilities,

        init_options = {
          formatting = true,
        },
        settings = {
          -- flags = { debounce_text_changes = 200 },

          solargraph = {
            autoformat = false,
            formatting = true,
            completion = true,
            diagnostics = true,
            folding = true,
            references = true,
            rename = true,
            symbols = true,
          },
        },
      })
      require("lspconfig").tsserver.setup({
        capabilities = capabilities,
        init_options = {
          hostInfo = "neovim",
          preferences = {
            importModuleSpecifierPreference = "non-relative",
          },
        },
        single_file_support = false,
      })

      require("lspconfig").bufls.setup({
        capabilities = capabilities,
      })

      require("lspconfig").eslint.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })

      require("lspconfig").lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })
    end,
  },

  -- Highlight, edit, and navigate code
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "RRethy/nvim-treesitter-endwise",
      "andymass/vim-matchup",
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = {
          enable = true,
        },
        ensure_installed = {
          "go",
          "gomod",
          "lua",
          "ruby",
          "vimdoc",
          "vim",
          "bash",
          "json",
          "markdown",
          "markdown_inline",
          "mermaid",
          "typescript",
          "javascript",
          "css",
          "html",
          "htmldjango",
          "proto",
          "python",
          "rust",
          "yaml",
          "bash",
          "tsx",
          "dockerfile",
        },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<space>", -- maps in normal mode to init the node/scope selection with space
            node_incremental = "<space>", -- increment to the upper named parent
            node_decremental = "<bs>", -- decrement to the previous node
            scope_incremental = "<tab>", -- increment to the upper scope (as defined in locals.scm)
          },
        },
        autopairs = {
          enable = true,
        },
        matchup = {
          enable = true,
        },
        highlight = {
          enable = true,

          -- Disable slow treesitter highlight for large files
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["iB"] = "@block.inner",
              ["aB"] = "@block.outer",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]]"] = "@function.outer",
            },
            goto_next_end = {
              ["]["] = "@function.outer",
            },
            goto_previous_start = {
              ["[["] = "@function.outer",
            },
            goto_previous_end = {
              ["[]"] = "@function.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>wn"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>wp"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
      })
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind-nvim",
    },
    enabled = function()
      -- disable completion in comments
      local context = require("cmp.config.context")
      -- keep command mode completion enabled when cursor is in a comment
      if vim.api.nvim_get_mode().mode == "c" then
        return true
      else
        return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
      end
    end,
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")

      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      luasnip.config.setup({
        history = true,
        region_check_events = "InsertEnter",
        delete_check_events = "TextChanged,InsertLeave",
      })

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      require("cmp").setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        formatting = {
          format = lspkind.cmp_format({
            with_text = true,
            menu = {
              path = "[Path]",
              buffer = "[Buffer]",
              nvim_lsp = "[LSP]",
              nvim_lua = "[Lua]",
            },
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            local copilot_keys = vim.fn["copilot#Accept"]()
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            elseif copilot_keys ~= "" and type(copilot_keys) == "string" then
              vim.api.nvim_feedkeys(copilot_keys, "i", true)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- don't auto select item
        preselect = cmp.PreselectMode.None,
        window = {
          documentation = cmp.config.window.bordered(),
        },
        view = {
          entries = {
            name = "custom",
            selection_order = "near_cursor",
          },
        },
        confirm_opts = {
          behavior = cmp.ConfirmBehavior.Insert,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip", keyword_length = 2 },
          { name = "buffer", keyword_length = 5 },
        },
      })
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
})

----------------
--- SETTINGS ---
----------------

-- disable netrw at the very start of our init.lua, because we use nvim-tree
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

-- Fast saving
vim.keymap.set("n", "<Leader>s", ":write!<CR>")
vim.keymap.set("n", "<Leader>q", ":q!<CR>", { silent = true })

-- Some useful quickfix shortcuts for quickfix
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-m>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>a", "<cmd>cclose<CR>")

-- Exit on jj and jk
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Exit on jj and jk
vim.keymap.set("i", "jj", "<ESC>")
vim.keymap.set("i", "jk", "<ESC>")

-- Remove search highlight
vim.keymap.set("n", "<Leader><space>", ":nohlsearch<CR>")

-- Don't jump forward if I higlight and search for a word
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

-- Better split switching
-- vim.keymap.set("", "<C-j>", "<C-W>j")
-- vim.keymap.set("", "<C-k>", "<C-W>k")
-- vim.keymap.set("", "<C-h>", "<C-W>h")
-- vim.keymap.set("", "<C-l>", "<C-W>l")

-- Visual linewise up and down by default (and use gj gk to go quicker)
vim.keymap.set("n", "<Up>", "gk")
vim.keymap.set("n", "<Down>", "gj")

-- Yanking a line should act like D and C
-- vim.keymap.set("n", "Y", "y$")

-- Terminal
-- Close terminal window, even if we are in insert mode
vim.keymap.set("t", "<leader>q", "<C-\\><C-n>:q<cr>")

-- switch to normal mode with esc
vim.keymap.set("t", "<ESC>", "<C-\\><C-n>")

-- Open terminal in vertical and horizontal split
vim.keymap.set("n", "<leader>tv", "<cmd>vnew term://zsh<CR>", { noremap = true })
vim.keymap.set("n", "<leader>ts", "<cmd>split term://zsh<CR>", { noremap = true })

-- Open terminal in vertical and horizontal split, inside the terminal
vim.keymap.set("t", "<leader>tv", "<c-w><cmd>vnew term://zsh<CR>", { noremap = true })
vim.keymap.set("t", "<leader>ts", "<c-w><cmd>split term://zsh<CR>", { noremap = true })

-- mappings to move out from terminal to other views
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- we don't use netrw (because of nvim-tree), hence re-implement gx to open
-- links in browser
vim.keymap.set("n", "gx", '<Cmd>call jobstart(["open", expand("<cfile>")], {"detach": v:true})<CR>')

-- automatically switch to insert mode when entering a Term buffer
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("openTermInsert", {}),
  callback = function(args)
    -- we don't use vim.startswith() and look for test:// because of vim-test
    -- vim-test starts tests in a terminal, which we want to keep in normal mode
    if vim.endswith(vim.api.nvim_buf_get_name(args.buf), "zsh") then
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

-- git.nvim
vim.keymap.set("n", "<leader>gb", '<CMD>lua require("git.blame").blame()<CR>')
vim.keymap.set("n", "<leader>go", "<CMD>lua require('git.browse').open(false)<CR>")
vim.keymap.set("x", "<leader>go", ":<C-u> lua require('git.browse').open(true)<CR>")

-- old habits
vim.api.nvim_create_user_command("GBrowse", 'lua require("git.browse").open(true)<CR>', {
  range = true,
  bang = true,
  nargs = "*",
})

vim.api.nvim_create_user_command("GBlame", 'lua require("git.blame").blame()<CR>', {})
vim.api.nvim_create_user_command("Gblame", 'lua require("git.blame").blame()<CR>', {})

-- File-tree mappings
vim.keymap.set("n", "<leader>n", ":NvimTreeToggle<CR>", { noremap = true })
vim.keymap.set("n", "<leader>e", ":NvimTreeFindFile<CR>f", { noremap = true })

-- File search
vim.keymap.set("n", "<leader>F", ":FZF<CR>")
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

-- telescope
vim.keymap.set("n", "<C-p>", builtin.git_files, {})
vim.keymap.set("n", "<C-b>", builtin.find_files, {})
vim.keymap.set("n", "<C-g>", builtin.lsp_document_symbols, {})
vim.keymap.set("n", "<leader>td", builtin.diagnostics, {})
vim.keymap.set("n", "<leader>gs", builtin.grep_string, {})
vim.keymap.set("n", "<leader>gg", builtin.live_grep, {})

-- diagnostics
vim.keymap.set("n", "<leader>do", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>ds", vim.diagnostic.setqflist)

-- vim-go
vim.keymap.set("n", "<leader>b", build_go_files)

-- disable diagnostics, I didn't like them
-- vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

-- Go uses gofmt, which uses tabs for indentation and spaces for aligment.
-- Hence override our indentation rules.
vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("setIndent", { clear = true }),
  pattern = { "go" },
  command = "setlocal noexpandtab tabstop=4 shiftwidth=4",
})

-- Update configuration for Markdown
vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("setIndent", { clear = true }),
  pattern = { "md" },
  command = "setlocal expandtab tabstop=2 shiftwidth=2",
})

-- Run gofmt/gofmpt, import packages automatically on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("setGoFormatting", { clear = true }),
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 2000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
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

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }

    -- Commented out native LSP keymaps,  it was bugging but good to know.
    -- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    -- vim.keymap.set("n", "<leader>v", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", opts)
    -- vim.keymap.set("n", "<leader>h", "<cmd>belowright split | lua vim.lsp.buf.definition()<CR>", opts)
    -- vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    -- vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

    vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
    vim.keymap.set("n", "gT", builtin.lsp_type_definitions, opts)

    vim.keymap.set("n", "<leader>v", "<cmd>vsplit | lua require('telescope.builtin').lsp_definitions()<CR>", opts)
    vim.keymap.set(
      "n",
      "<leader>h",
      "<cmd>belowright split| lua require('telescope.builtin').lsp_definitions()<CR>",
      opts
    )

    vim.keymap.set("n", "gr", builtin.lsp_references, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)

    vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})

-- automatically resize all vim buffers if I resize the terminal window
vim.api.nvim_command("autocmd VimResized * wincmd =")

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
vim.cmd([[
augroup highlight_yank
autocmd!
au TextYankPost * silent! lua vim.highlight.on_yank({higroup="Visual", timeout=200})
augroup END
]])
