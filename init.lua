-- bootstrap lazy.nvim, LazyVim and your plugins
-- This comes first, because we have mappings that depend on leader
-- With a map leader it's possible to do extra key combinations
-- i.e: <leader>w saves the current file
vim.g.mapleader = ","

-- Load config files
require("config.options")
require("config.keymaps")
require("config.autocmds")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Always keep a black background
vim.o.background = "dark"

-- Save undo history
vim.o.undofile = true

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

        return { timeout_ms = 200, lsp_format = "fallback" }, on_format
      end,

      format_after_save = function(bufnr)
        if not slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return { lsp_format = "fallback" }
      end,

      formatters = {
        stylua = {
          prepend_args = { "--indent-width", 2, "--indent-type", "Spaces" },
        },
        rubocop = {
          prepend_args = { "--force-exclusion" },
        },
      },

      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        ruby = { "rubocop" },
        go = { "gofumpt", "gofmt" },
        ["javascript"] = { "prettier" },
        ["javascriptreact"] = { "prettier" },
        ["typescript"] = { "prettier" },
        ["typescriptreact"] = { "prettier" },
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

  -- fzf-lua: Fuzzy finder and picker
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional for icon support
    config = function()
      require("fzf-lua").setup({
        -- Customize your fzf-lua setup here if needed
      })
    end,
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
      { "<leader>tn", ":TestNearest<CR>", { noremap = true, silent = true }, desc = "Test Nearest" },
      { "<leader>tf", ":TestFile<CR>", { noremap = true, silent = true }, desc = "Test File" },
      { "<leader>ta", ":TestSuite<CR>", { noremap = true, silent = true }, desc = "Test Suite" },
      { "<leader>tl", ":TestLast<CR>", { noremap = true, silent = true }, desc = "Test Last" },
    },
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#start_normal"] = "1"
      vim.g["test#ruby#rails#options"] = "--verbose"
      vim.g["test#ruby#minitest#options"] = "--verbose"
      vim.g["test#javascript#jest#options"] = "--verbose"
      vim.g["test#go#gotest#options"] = "-v"
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
  -- configuration taken from here: https://github.com/MariaSolOs/dotfiles/blob/e9eb1f8e027840f872e69e00e082e2be10237499/.config/nvim/lua/plugins/copilot.lua
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    lazy = true,
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        hide_during_completion = false,
        keymap = {
          accept = "<C-l>",
          accept_word = "<M-w>",
          accept_line = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      filetypes = { markdown = true },
    },
    config = function(_, opts)
      local copilot = require("copilot.suggestion")
      local luasnip = require("luasnip")

      require("copilot").setup(opts)

      local function set_trigger(trigger)
        vim.b.copilot_suggestion_auto_trigger = trigger
        vim.b.copilot_suggestion_hidden = not trigger
      end

      -- Disable suggestions when inside a snippet.
      vim.api.nvim_create_autocmd("User", {
        pattern = { "LuasnipInsertNodeEnter", "LuasnipInsertNodeLeave" },
        callback = function()
          set_trigger(not luasnip.expand_or_locally_jumpable())
        end,
      })
    end,
  },

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

  -- rooter (vim-ripgrep and ack.vim removed - fzf-lua provides grep functionality)
  { "airblade/vim-rooter" },

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
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Mason for installing LSP servers
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "lua_ls", "ts_ls", "ruby_lsp", "gopls", "buf_ls", "eslint" },
    },
    dependencies = {
      "mason-org/mason.nvim",
    },
  },

  -- LSP configuration using Neovim 0.11+ native API (vim.lsp.config)
  {
    "Saghen/blink.cmp", -- Just to ensure blink.cmp loads first for capabilities
    optional = true,
  },
  {
    "neovim/nvim-lspconfig", -- Still needed for filetype detection and root_dir utilities
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Use blink.cmp capabilities for better completion support
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Helper to get root directory patterns
      local function root_pattern(...)
        local patterns = { ... }
        return function(fname)
          for _, pattern in ipairs(patterns) do
            local match = vim.fs.find(pattern, { path = fname, upward = true })[1]
            if match then
              return vim.fn.fnamemodify(match, ":h")
            end
          end
        end
      end

      -- Configure LSP servers using Neovim 0.11 native API
      vim.lsp.config("gopls", {
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

      vim.lsp.config("ruby_lsp", {
        capabilities = capabilities,
        cmd = { vim.fn.expand("~/.rbenv/shims/ruby-lsp") },
        filetypes = { "ruby", "eruby" },
      })

      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        init_options = {
          hostInfo = "neovim",
          preferences = {
            importModuleSpecifierPreference = "non-relative",
          },
        },
        single_file_support = false,
      })

      vim.lsp.config("buf_ls", {
        capabilities = capabilities,
      })

      vim.lsp.config("astro", {
        capabilities = capabilities,
        filetypes = { "astro" },
        root_dir = root_pattern("astro.config.mjs", "astro.config.js", "astro.config.ts"),
      })

      vim.lsp.config("eslint", {
        capabilities = capabilities,
      })

      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Enable all configured LSP servers
      vim.lsp.enable({ "gopls", "ruby_lsp", "ts_ls", "buf_ls", "astro", "eslint", "lua_ls" })

      -- ESLint fix on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
        callback = function(args)
          local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" })
          if #clients > 0 then
            vim.cmd("EslintFixAll")
          end
        end,
      })

      -- TypeScript remove unused imports on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("ts_imports", { clear = true }),
        pattern = { "*.tsx", "*.ts" },
        callback = function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { "source.removeUnused.ts" },
              diagnostics = {},
            },
          })
        end,
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
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.blade = {
        install_info = {
          url = "https://github.com/EmranMR/tree-sitter-blade",
          files = { "src/parser.c" },
          branch = "main",
        },
        filetype = "blade",
      }
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
          "php_only",
          "blade",
          "svelte",
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
          config = function()
            vim.g.matchup_matchparen_offscreen = { method = "popup" }
          end,
        },
        highlight = {
          enable = true,

          -- Disable slow treesitter highlight for large files
          disable = function(_, buf)
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

      vim.filetype.add({
        pattern = {
          [".*%.blade%.php"] = "blade",
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

  -- autocompletion (blink-cmp replaces nvim-cmp)
  {
    "Saghen/blink.cmp",
    version = "1.*", -- Use a stable release with prebuilt binaries
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("blink.cmp").setup({
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },
        snippets = {
          preset = "luasnip",
        },
        keymap = {
          preset = "default",
          ["<CR>"] = { "accept", "fallback" }, -- Accept and enter, or fallback if not applicable
          ["<Tab>"] = { "select_next", "fallback" }, -- Next item, or fallback
          ["<S-Tab>"] = { "select_prev", "fallback" }, -- Previous item, or fallback
          ["<C-e>"] = { "cancel", "fallback" }, -- Cancel completion, or fallback
          ["<C-d>"] = { "scroll_documentation_up", "fallback" },
          ["<C-f>"] = { "scroll_documentation_down", "fallback" },
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
      "TmuxNavigatorProcessList",
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

  -- trouble.nvim for better diagnostics UI
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
    opts = {},
  },
})

------------------
--- POST-SETUP ---
------------------

-- === FZF-LUA KEYMAPS ===
local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "FzfLua Files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "FzfLua Live Grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "FzfLua Buffers" })
vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "FzfLua Help Tags" })
vim.keymap.set("n", "<C-p>", fzf.git_files, { desc = "FzfLua Git Files" })
vim.keymap.set("n", "<C-b>", fzf.files, { desc = "FzfLua Files" })
vim.keymap.set("n", "<C-g>", fzf.lsp_document_symbols, { desc = "FzfLua LSP Document Symbols" })
vim.keymap.set("n", "<leader>td", fzf.diagnostics_document, { desc = "FzfLua Diagnostics (Document)" })
vim.keymap.set("n", "<leader>gs", fzf.grep_cword, { desc = "FzfLua Grep Word Under Cursor" })
vim.keymap.set("n", "<leader>gg", fzf.live_grep, { desc = "FzfLua Live Grep" })
vim.keymap.set("n", "<leader>fp", fzf.oldfiles, { desc = "FzfLua OldFiles" })
vim.keymap.set("n", "<leader>ch", fzf.command_history, { desc = "FzfLua Command History" })

vim.keymap.set("n", "<leader>F", ":FzfLua files<CR>")

-- vim-go
vim.keymap.set("n", "<leader>b", build_go_files)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }

    vim.keymap.set("n", "<leader>v", function()
      fzf.lsp_definitions({ jump_to_single = false, winopts = { split = "vsplit" } })
    end, opts)
    vim.keymap.set("n", "<leader>h", function()
      fzf.lsp_definitions({ jump_to_single = false, winopts = { split = "split" } })
    end, opts)
    vim.keymap.set("n", "gd", fzf.lsp_definitions, opts)
    vim.keymap.set("n", "gT", fzf.lsp_typedefs, opts)
    vim.keymap.set("n", "gr", fzf.lsp_references, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", fzf.lsp_implementations, opts)

    vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})
