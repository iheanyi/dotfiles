-- Semantic highlight group applicator (~80 groups covering UI, Treesitter, LSP, diagnostics, and core plugins)
-- plus a standalone zero-dependency `colors/<name>.lua` exporter.
local M = {}

--- Build the complete highlight specification table from a generated palette.
function M.spec(p)
  local italic = p.italics ~= false
  local syn = p.syn

  return {
    -- Core UI
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_float },
    FloatBorder = { fg = p.border, bg = p.bg_float },
    FloatTitle = { fg = p.accent, bg = p.bg_float, bold = true },
    Cursor = { fg = p.bg, bg = p.cursor },
    CursorLine = { bg = p.bg_line },
    CursorColumn = { bg = p.bg_line },
    ColorColumn = { bg = p.bg_alt },
    LineNr = { fg = p.fg_dim },
    CursorLineNr = { fg = p.fg, bg = p.bg_line, bold = true },
    SignColumn = { fg = p.fg_dim, bg = p.bg },
    FoldColumn = { fg = p.fg_dim, bg = p.bg },
    Folded = { fg = p.fg_muted, bg = p.bg_float },
    Visual = { bg = p.bg_sel },
    VisualNOS = { bg = p.bg_sel },
    Search = { fg = p.fg, bg = p.search_bg },
    IncSearch = { fg = p.bg, bg = p.incsearch_bg, bold = true },
    CurSearch = { fg = p.bg, bg = p.incsearch_bg, bold = true },
    Substitute = { fg = p.bg, bg = p.error, bold = true },
    MatchParen = { fg = p.accent, bg = p.bg_sel_neutral, bold = true },
    StatusLine = { fg = p.fg, bg = p.bg_float },
    StatusLineNC = { fg = p.fg_muted, bg = p.bg_alt },
    WinSeparator = { fg = p.border },
    VertSplit = { fg = p.border },
    TabLine = { fg = p.fg_muted, bg = p.bg_alt },
    TabLineFill = { bg = p.bg_alt },
    TabLineSel = { fg = p.fg, bg = p.bg, bold = true },
    WinBar = { fg = p.fg_subtle, bg = p.bg },
    WinBarNC = { fg = p.fg_muted, bg = p.bg },
    Pmenu = { fg = p.fg, bg = p.bg_float },
    PmenuSel = { fg = p.fg, bg = p.bg_sel, bold = true },
    PmenuSbar = { bg = p.bg_alt },
    PmenuThumb = { bg = p.border },
    NonText = { fg = p.fg_dim },
    Whitespace = { fg = p.fg_dim },
    SpecialKey = { fg = p.fg_dim },
    EndOfBuffer = { fg = p.bg_line },
    Title = { fg = p.accent, bold = true },
    Directory = { fg = p.accent },
    Conceal = { fg = p.fg_muted },
    ErrorMsg = { fg = p.error, bold = true },
    WarningMsg = { fg = p.warn, bold = true },
    MoreMsg = { fg = p.ok },
    ModeMsg = { fg = p.fg_subtle, bold = true },
    Question = { fg = p.info },
    QuickFixLine = { bg = p.bg_sel, bold = true },

    -- Classic syntax (fallback for all regex & Treesitter languages)
    Comment = { fg = p.fg_muted, italic = italic },
    Constant = { fg = syn.constant },
    String = { fg = syn.string },
    Character = { fg = syn.string },
    Number = { fg = syn.number },
    Boolean = { fg = syn.constant },
    Float = { fg = syn.number },
    Identifier = { fg = syn.variable },
    Function = { fg = syn.func },
    Statement = { fg = syn.keyword },
    Conditional = { fg = syn.keyword },
    Repeat = { fg = syn.keyword },
    Label = { fg = syn.keyword },
    Operator = { fg = syn.operator },
    Keyword = { fg = syn.keyword },
    Exception = { fg = syn.keyword },
    PreProc = { fg = syn.keyword },
    Include = { fg = syn.keyword },
    Define = { fg = syn.keyword },
    Macro = { fg = syn.special },
    Type = { fg = syn.type },
    StorageClass = { fg = syn.keyword },
    Structure = { fg = syn.type },
    Typedef = { fg = syn.type },
    Special = { fg = syn.special },
    SpecialChar = { fg = syn.special },
    Tag = { fg = syn.tag },
    Delimiter = { fg = syn.punctuation },
    SpecialComment = { fg = p.fg_subtle, italic = italic },
    Underlined = { underline = true },
    Error = { fg = p.error },
    Todo = { fg = p.bg, bg = p.warn, bold = true },

    -- Treesitter semantic normalization (works across Go, Ruby, TS, Lua, Astro, Markdown, etc.)
    ["@comment"] = { link = "Comment" },
    ["@variable"] = { fg = syn.variable },
    ["@variable.builtin"] = { fg = syn.special, italic = italic },
    ["@variable.parameter"] = { fg = syn.parameter },
    ["@variable.member"] = { fg = syn.property },
    ["@property"] = { fg = syn.property },
    ["@constant"] = { fg = syn.constant },
    ["@constant.builtin"] = { fg = syn.constant },
    ["@module"] = { fg = p.fg_subtle },
    ["@string"] = { fg = syn.string },
    ["@string.escape"] = { fg = syn.special },
    ["@string.regexp"] = { fg = syn.special },
    ["@string.special.url"] = { fg = p.info, underline = true },
    ["@number"] = { fg = syn.number },
    ["@boolean"] = { fg = syn.constant },
    ["@function"] = { fg = syn.func },
    ["@function.builtin"] = { fg = syn.func },
    ["@function.method"] = { fg = syn.func },
    ["@constructor"] = { fg = syn.type },
    ["@keyword"] = { fg = syn.keyword },
    ["@keyword.return"] = { fg = syn.keyword },
    ["@keyword.operator"] = { fg = syn.operator },
    ["@keyword.import"] = { fg = syn.keyword },
    ["@type"] = { fg = syn.type },
    ["@type.builtin"] = { fg = syn.type },
    ["@operator"] = { fg = syn.operator },
    ["@punctuation.delimiter"] = { fg = syn.punctuation },
    ["@punctuation.bracket"] = { fg = syn.punctuation },
    ["@punctuation.special"] = { fg = syn.special },
    ["@tag"] = { fg = syn.tag },
    ["@tag.attribute"] = { fg = syn.property },
    ["@tag.delimiter"] = { fg = syn.punctuation },
    ["@markup.heading"] = { fg = p.accent, bold = true },
    ["@markup.strong"] = { fg = p.fg, bold = true },
    ["@markup.italic"] = { fg = p.fg, italic = true },
    ["@markup.raw"] = { fg = syn.string },
    ["@markup.link"] = { fg = p.info },
    ["@markup.link.url"] = { fg = p.fg_subtle, underline = true },
    ["@markup.list"] = { fg = syn.punctuation },
    ["@markup.quote"] = { fg = p.fg_muted, italic = italic },
    ["@diff.plus"] = { fg = p.ok },
    ["@diff.minus"] = { fg = p.error },
    ["@diff.delta"] = { fg = p.info },

    -- LSP semantic tokens & hints
    ["@lsp.type.variable"] = { link = "@variable" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.function"] = { link = "@function" },
    ["@lsp.type.method"] = { link = "@function.method" },
    ["@lsp.type.type"] = { link = "@type" },
    ["@lsp.type.keyword"] = { link = "@keyword" },
    ["@lsp.type.comment"] = { link = "@comment" },
    LspInlayHint = { fg = p.fg_muted, bg = p.bg_alt, italic = italic },
    LspReferenceText = { bg = p.bg_sel_neutral },
    LspReferenceRead = { bg = p.bg_sel_neutral },
    LspReferenceWrite = { bg = p.bg_sel, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = p.error },
    DiagnosticWarn = { fg = p.warn },
    DiagnosticInfo = { fg = p.info },
    DiagnosticHint = { fg = p.hint },
    DiagnosticOk = { fg = p.ok },
    DiagnosticVirtualTextError = { fg = p.error, bg = p.error_bg },
    DiagnosticVirtualTextWarn = { fg = p.warn, bg = p.warn_bg },
    DiagnosticVirtualTextInfo = { fg = p.info, bg = p.info_bg },
    DiagnosticVirtualTextHint = { fg = p.hint, bg = p.info_bg },
    DiagnosticUnderlineError = { undercurl = true, sp = p.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.warn },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.info },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.hint },

    -- Diffs & Git
    Added = { fg = p.ok },
    Changed = { fg = p.info },
    Removed = { fg = p.error },
    DiffAdd = { bg = p.diff_add_bg },
    DiffChange = { bg = p.diff_change_bg },
    DiffDelete = { fg = p.error, bg = p.diff_del_bg },
    DiffText = { bg = p.diff_text_bg, bold = true },
    GitSignsAdd = { fg = p.ok },
    GitSignsChange = { fg = p.info },
    GitSignsDelete = { fg = p.error },

    -- Targeted links for your active plugins (snacks, fzf-lua, blink.cmp, render-markdown, oil)
    SnacksPickerNormal = { fg = p.fg, bg = p.bg_float },
    SnacksPickerBorder = { fg = p.border, bg = p.bg_float },
    SnacksPickerTitle = { fg = p.accent, bg = p.bg_float, bold = true },
    SnacksPickerMatch = { fg = p.accent, bold = true },
    SnacksPickerPrompt = { fg = p.accent },
    FzfLuaNormal = { fg = p.fg, bg = p.bg_float },
    FzfLuaBorder = { fg = p.border, bg = p.bg_float },
    FzfLuaTitle = { fg = p.accent, bg = p.bg_float, bold = true },
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_float },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpMenuSelection = { fg = p.fg, bg = p.bg_sel, bold = true },
    BlinkCmpLabelMatch = { fg = p.accent, bold = true },
    BlinkCmpGhostText = { fg = p.fg_muted, italic = italic },
    RenderMarkdownH1Bg = { fg = p.accent, bg = p.bg_line, bold = true },
    RenderMarkdownH2Bg = { fg = p.accent2, bg = p.bg_line, bold = true },
    RenderMarkdownH3Bg = { fg = p.accent3, bg = p.bg_line, bold = true },
    RenderMarkdownCode = { bg = p.bg_alt },
    OilDir = { fg = p.accent, bold = true },
  }
end

--- Apply a generated palette live to Neovim.
function M.apply(palette, opts)
  opts = opts or {}
  vim.o.background = palette.polarity == "light" and "light" or "dark"

  if opts.clear then
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then
      vim.cmd("syntax reset")
    end
  end

  local groups = M.spec(palette)
  for name, val in pairs(groups) do
    vim.api.nvim_set_hl(0, name, val)
  end

  if palette.ansi then
    for i = 0, 15 do
      if palette.ansi[i] then
        vim.g["terminal_color_" .. i] = palette.ansi[i]
      end
    end
  end

  if opts.name then
    vim.g.colors_name = opts.name
  end

  if opts.notify_colorscheme ~= false then
    pcall(vim.api.nvim_exec_autocmds, "ColorScheme", { modeline = false })
  end
end

local function format_hl_val(v)
  local parts = {}
  local keys = { "link", "fg", "bg", "sp", "bold", "italic", "underline", "undercurl" }
  for _, k in ipairs(keys) do
    local val = v[k]
    if val ~= nil then
      if type(val) == "string" then
        parts[#parts + 1] = string.format("%s = %q", k, val)
      else
        parts[#parts + 1] = string.format("%s = %s", k, tostring(val))
      end
    end
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

--- Generate a clean, standalone, zero-dependency `colors/<name>.lua` file.
function M.export_neovim_lua(slug, palette, state)
  local groups = M.spec(palette)
  local names = vim.tbl_keys(groups)
  table.sort(names)

  local lines = {
    "-- " .. slug .. " — generated by themenav (OKLCH Studio)",
    string.format(
      "-- Recipe: preset=%s mode=%s polarity=%s depth=%.2f contrast=%.2f chroma=%.2f hue=%d tint=%d@%.3f harmony=%s restraint=%s",
      tostring(state.preset_id),
      tostring(state.mode),
      tostring(state.polarity),
      state.depth or 0,
      state.contrast or 1,
      state.chroma or 1,
      math.floor((state.hue_shift or 0) + 0.5),
      math.floor((state.tint_hue or 0) + 0.5),
      state.tint_strength or 0,
      tostring(state.harmony),
      tostring(state.restraint)
    ),
    string.format(
      "-- Contrast (APCA): FG Lc %d | Comment Lc %d | Accent Lc %d",
      palette.metrics.apca_fg,
      palette.metrics.apca_comment,
      palette.metrics.apca_accent
    ),
    "",
    string.format("vim.o.background = %q", palette.polarity == "light" and "light" or "dark"),
    'vim.cmd("highlight clear")',
    'if vim.fn.exists("syntax_on") == 1 then',
    '  vim.cmd("syntax reset")',
    "end",
    string.format("vim.g.colors_name = %q", slug),
    "",
    "local groups = {",
  }

  for _, name in ipairs(names) do
    lines[#lines + 1] = string.format("  [%q] = %s,", name, format_hl_val(groups[name]))
  end

  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "for name, val in pairs(groups) do"
  lines[#lines + 1] = "  vim.api.nvim_set_hl(0, name, val)"
  lines[#lines + 1] = "end"
  lines[#lines + 1] = ""

  if palette.ansi then
    for i = 0, 15 do
      if palette.ansi[i] then
        lines[#lines + 1] = string.format("vim.g.terminal_color_%d = %q", i, palette.ansi[i])
      end
    end
    lines[#lines + 1] = ""
  end

  return table.concat(lines, "\n")
end

return M
