return {
  -- Import LazyVim's Rust extras (includes rust-analyzer, crates.nvim, etc.)
  { import = "lazyvim.plugins.extras.lang.rust" },

  -- Ensure rust-analyzer and other Rust tools are installed via Mason
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "rust-analyzer",
      },
    },
  },

  -- Add Rust to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "rust", "toml" })
    end,
  },
}
