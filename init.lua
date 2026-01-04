-- bootstrap lazy.nvim, LazyVim and your plugins
-- This comes first, because we have mappings that depend on leader
-- With a map leader it's possible to do extra key combinations
-- i.e: <leader>w saves the current file
vim.g.mapleader = ","

-- Load config files
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load private/work-specific config if available (gitignored)
local private_ok, private = pcall(require, "private")
if not private_ok then
  private = {}
end

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

-- Build plugin list
local plugins = {
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true, -- loaded by treesitter or when needed
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
    keys = {
      { "gsa", mode = { "n", "v" }, desc = "Add surrounding" },
      { "gsd", desc = "Delete surrounding" },
      { "gsf", desc = "Find surrounding (right)" },
      { "gsF", desc = "Find surrounding (left)" },
      { "gsh", desc = "Highlight surrounding" },
      { "gsr", desc = "Replace surrounding" },
      { "gsn", desc = "Update n_lines" },
    },
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
      -- Build lualine_x section with optional status
      local lualine_x = { "filetype" }
      if private.lualine_x then
        lualine_x = vim.list_extend(vim.deepcopy(private.lualine_x), lualine_x)
      end

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
          lualine_x = lualine_x,
        },
      })
    end,
  },

  -- better UI for code actions
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- Better input prompts (vim.ui.input)
      input = { enabled = true },
      -- Better select menus (vim.ui.select) - used by code actions
      picker = {
        ui_select = true,
      },
      -- Notification system
      notifier = {
        enabled = true,
        top_down = false,
      },
    },
  },
  -- formatter
  {
    "stevearc/conform.nvim",
    config = function()
      -- Base formatters_by_ft
      local formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        ruby = { "rubocop" },
        go = { "gofumpt", "gofmt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        astro = { "prettier" },
      }

      -- Merge private/work formatters if available
      if private.formatters_by_ft then
        formatters_by_ft = vim.tbl_extend("force", formatters_by_ft, private.formatters_by_ft)
      end

      require("conform").setup({
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

        formatters_by_ft = formatters_by_ft,
      })
    end,
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

  -- testing framework (neotest)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Language adapters
      "nvim-neotest/neotest-go",
      "olimorris/neotest-rspec",
      "nvim-neotest/neotest-jest",
      "stevearc/overseer.nvim",
    },
    keys = {
      {
        "<leader>tn",
        function()
          require("neotest").run.run()
        end,
        desc = "Test Nearest",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Test File",
      },
      {
        "<leader>tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Test Last",
      },
      {
        "<leader>ta",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Test All (Summary)",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true })
        end,
        desc = "Test Output",
      },
      {
        "<leader>tO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Test Output Panel",
      },
      {
        "<leader>tS",
        function()
          require("neotest").run.stop()
        end,
        desc = "Test Stop",
      },
    },
    config = function()
      -- Build adapters list
      local adapters = {
        require("neotest-go"),
        require("neotest-rspec"),
        require("neotest-jest")({
          jestCommand = "npm test --",
          cwd = function()
            return vim.fn.getcwd()
          end,
        }),
      }

      -- Add private/work adapters if available
      if private.get_neotest_adapters then
        local private_adapters = private.get_neotest_adapters()
        for _, adapter in ipairs(private_adapters) do
          table.insert(adapters, adapter)
        end
      end

      require("neotest").setup({
        adapters = adapters,
        status = { virtual_text = true },
        output = { open_on_run = false },
        quickfix = {
          open = function()
            vim.cmd("copen")
          end,
        },
        consumers = {
          overseer = require("neotest.consumers.overseer"),
        },
      })
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

  -- file explorer (oil.nvim - edit filesystem like a buffer)
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = { "icon" },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
        },
      })
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },

  {
    "AndrewRadev/splitjoin.vim",
    keys = {
      { "gS", desc = "Split line" },
      { "gJ", desc = "Join lines" },
    },
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
    cmd = { "Other", "OtherSplit", "OtherVSplit", "OtherTabNew", "OtherClear" },
    keys = {
      { "<leader>ll", "<cmd>Other<CR>", desc = "Other file" },
      { "<leader>lh", "<cmd>OtherSplit<CR>", desc = "Other file (split)" },
      { "<leader>lv", "<cmd>OtherVSplit<CR>", desc = "Other file (vsplit)" },
      { "<leader>lc", "<cmd>OtherClear<CR>", desc = "Other clear" },
      { "<leader>ln", "<cmd>OtherTabNew<CR>", desc = "Other file (tab)" },
      { "<leader>lt", "<cmd>Other test<CR>", desc = "Other test file" },
    },
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
      -- Note: keymaps are defined in the `keys` spec above for lazy-loading
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
      ensure_installed = { "lua_ls", "ts_ls", "ruby_lsp", "gopls", "buf_ls", "eslint", "astro" },
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
      -- Note: When private config is loaded, it may provide custom LSP wrappers
      -- that replace the base servers for better monorepo support
      local base_servers = { "gopls", "ruby_lsp", "ts_ls", "buf_ls", "astro", "eslint", "lua_ls" }

      if private.setup_lsp then
        -- Private config may have its own gopls and ruby wrappers, so exclude the base ones
        base_servers = vim.tbl_filter(function(server)
          return server ~= "gopls" and server ~= "ruby_lsp"
        end, base_servers)
      end

      vim.lsp.enable(base_servers)

      -- Enable private/work LSP servers if available
      if private.setup_lsp then
        private.setup_lsp()
      end

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
          "astro",
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
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
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
    event = "InsertEnter",
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
      -- Note: LuaSnip is already loaded by its own plugin config, no need to call lazy_load() again
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

  -- Git commands
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    init = function()
      -- Support GitHub enterprise (configured in private config if needed)
      if private.github_enterprise_urls then
        vim.g.github_enterprise_urls = private.github_enterprise_urls
      end
    end,
  },

  -- Task runner
  {
    "stevearc/overseer.nvim",
    opts = {
      templates = { "builtin" },
    },
    config = function(_, opts)
      require("overseer").setup(opts)
      vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<CR>", { desc = "[O]verseer [T]oggle" })
      vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>", { desc = "[O]verseer [R]un" })
      vim.keymap.set("n", "<leader>oq", "<cmd>OverseerQuickAction<CR>", { desc = "[O]verseer [Q]uick action" })
      vim.keymap.set("n", "<leader>oa", "<cmd>OverseerTaskAction<CR>", { desc = "[O]verseer task [A]ction" })
    end,
  },
}

-- Merge private/work plugins if available
if private.plugins then
  for _, plugin in ipairs(private.plugins) do
    table.insert(plugins, plugin)
  end
end

require("lazy").setup(plugins)

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

    -- Inlay hints (Neovim 0.10+)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
      end, { buffer = ev.buf, desc = "Toggle inlay hints" })
    end
  end,
})
