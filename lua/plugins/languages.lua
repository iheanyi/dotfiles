return {
  -- Treesitter parsers for all languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "astro",
        "bash",
        "css",
        "go",
        "gomod",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ruby",
        "scss",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },

  -- Register .mdx files for markdown treesitter + spellcheck
  {
    "LazyVim/LazyVim",
    init = function()
      vim.filetype.add({
        extension = {
          mdx = "mdx",
        },
      })
      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
