-- Multi-language syntax, diagnostic, and diff preview specimens for ThemeNav.
local M = {}

local NS = vim.api.nvim_create_namespace("themenav_specimen")

M.list = {
  {
    id = "tsx",
    label = "TypeScript / React",
    ft = "typescriptreact",
    lines = {
      "// ThemeNav specimen — TypeScript / React (TSX)",
      'import { useMemo, useState } from "react";',
      "",
      "interface PaletteToken {",
      "  readonly id: string;",
      "  lightness: number;",
      "  chroma: number;",
      "  hue: number;",
      "}",
      "",
      "const APCA_MIN_BODY = 75;",
      "const HEX_RE = /^#[0-9a-f]{6}$/i;",
      "",
      "export function ContrastBadge<T extends PaletteToken>({",
      "  token,",
      '  background = "#141312",',
      "  onSelect,",
      "}: {",
      "  token: T;",
      "  background?: string;",
      "  onSelect: (id: string) => void;",
      "}) {",
      "  const [active, setActive] = useState(false);",
      "  const label = useMemo(() => {",
      "    // TODO: add Display P3 gamut indicator",
      "    const valid = HEX_RE.test(background);",
      '    return valid ? `${token.id} · L${token.lightness.toFixed(2)}` : "invalid";',
      "  }, [token, background]);",
      "",
      "  return (",
      '    <button className="badge" data-active={active} onClick={() => onSelect(token.id)}>',
      "      <span>{label}</span>",
      "      <strong>{APCA_MIN_BODY}+</strong>",
      "    </button>",
      "  );",
      "}",
    },
    signs = {
      { line = 4, text = "┃", hl = "GitSignsAdd" },
      { line = 5, text = "┃", hl = "GitSignsAdd" },
      { line = 24, text = "┃", hl = "GitSignsChange" },
      { line = 25, text = "┃", hl = "GitSignsChange" },
      { line = 32, text = "▁", hl = "GitSignsDelete" },
    },
    diagnostics = {
      { line = 26, col = 10, end_col = 15, sev = "hint", msg = "● Hint: redundant local binding `valid`" },
      { line = 27, col = 63, end_col = 72, sev = "warn", msg = "▲ Warn: fallback string not localized" },
      { line = 33, col = 15, end_col = 28, sev = "error", msg = "✖ Error: `APCA_MIN_BODY` contrast check mock" },
    },
  },
  {
    id = "go",
    label = "Go",
    ft = "go",
    lines = {
      "// ThemeNav specimen — Go",
      "package palette",
      "",
      "import (",
      '	"context"',
      '	"fmt"',
      '	"math"',
      ")",
      "",
      "type Swatch struct {",
      '	Name string  `json:"name"`',
      '	Hex  string  `json:"hex"`',
      '	Lc   float64 `json:"lc"`',
      "}",
      "",
      "const MinContrast = 75.0",
      "",
      "func Verify(ctx context.Context, swatches []Swatch) (int, error) {",
      "	if len(swatches) == 0 {",
      '		return 0, fmt.Errorf("empty palette: %w", context.Canceled)',
      "	}",
      "",
      "	passing := 0",
      "	for _, s := range swatches {",
      "		// Check perceptual APCA floor against canvas",
      "		if math.Abs(s.Lc) >= MinContrast {",
      "			passing++",
      "		}",
      "	}",
      "	return passing, nil",
      "}",
    },
    signs = {
      { line = 10, text = "┃", hl = "GitSignsAdd" },
      { line = 11, text = "┃", hl = "GitSignsAdd" },
      { line = 26, text = "┃", hl = "GitSignsChange" },
    },
    diagnostics = {
      { line = 19, col = 12, end_col = 23, sev = "warn", msg = "▲ Warn: wrapped sentinel error" },
      { line = 26, col = 6, end_col = 14, sev = "info", msg = "ℹ Info: APCA floor verified in OKLCH" },
    },
  },
  {
    id = "ruby",
    label = "Ruby / Rails",
    ft = "ruby",
    lines = {
      "# ThemeNav specimen — Ruby / Rails",
      "module ThemeStudio",
      "  class Palette < ApplicationRecord",
      "    MIN_CONTRAST = 75",
      "    HEX_PATTERN = /A#[0-9a-f]{6}\z/i",
      "",
      "    belongs_to :workspace",
      "    has_many :tokens, dependent: :destroy",
      "",
      "    scope :dark_mode, -> { where(polarity: :dark) }",
      "",
      "    def remaster(depth: -0.08, chroma: 0.92)",
      "      # Normalize accents while keeping variables neutral",
      "      tokens.map do |token|",
      '        score = "#{token.role}: Lc=#{token.contrast.round}"',
      "        { id: token.id, hex: token.shift(depth:, chroma:), score: }",
      "      end",
      "    rescue ArgumentError => e",
      '      Rails.logger.warn("Remaster skipped: #{e.message}")',
      "      []",
      "    end",
      "  end",
      "end",
    },
    signs = {
      { line = 10, text = "┃", hl = "GitSignsAdd" },
      { line = 15, text = "┃", hl = "GitSignsChange" },
      { line = 19, text = "▁", hl = "GitSignsDelete" },
    },
    diagnostics = {
      { line = 15, col = 8, end_col = 13, sev = "hint", msg = "● Hint: local variable `score` preview" },
      { line = 19, col = 6, end_col = 18, sev = "warn", msg = "▲ Warn: rescued ArgumentError" },
    },
  },
  {
    id = "lua",
    label = "Lua / Neovim",
    ft = "lua",
    lines = {
      "-- ThemeNav specimen — Lua (Neovim)",
      'local oklch = require("themenav.oklch")',
      "",
      "local M = { version = 1.0, strict = true }",
      "",
      "local function derive_surface(bg_hex, step, tint_hue)",
      "  local L, C, H = oklch.hex_to_oklch(bg_hex)",
      "  local next_L = math.max(0.08, math.min(0.98, L + step))",
      "  return oklch.oklch_to_hex(next_L, C, tint_hue or H)",
      "end",
      "",
      "function M.build(seed)",
      '  assert(type(seed) == "table", "expected seed table")',
      "  local surfaces = {}",
      "  for idx, delta in ipairs({ -0.02, 0.0, 0.04, 0.09 }) do",
      "    surfaces[idx] = derive_surface(seed.bg, delta, seed.tint)",
      "  end",
      "  return surfaces",
      "end",
      "",
      "return M",
    },
    signs = {
      { line = 6, text = "┃", hl = "GitSignsAdd" },
      { line = 15, text = "┃", hl = "GitSignsChange" },
    },
    diagnostics = {
      { line = 8, col = 8, end_col = 14, sev = "info", msg = "ℹ Info: OKLCH L step preserves hue" },
    },
  },
  {
    id = "markdown",
    label = "Markdown",
    ft = "markdown",
    lines = {
      "# Merino & OKLCH Theme Notes",
      "",
      "A calm theme uses an **80 / 15 / 5** visual budget: neutral surfaces and",
      "variables, restrained accents, and *harmonized* diagnostic hues.",
      "",
      "## Design Rules",
      "",
      "- Keep variables and punctuation on the neutral ramp",
      "- Repair contrast by moving `L` only — never by cranking saturation",
      "- Reference: [OKLab color space](https://bottosson.github.io/posts/oklab/)",
      "",
      "### Code & Callouts",
      "",
      "> Good contrast feels effortless before you ever notice the colors.",
      "",
      "```lua",
      'local hex = oklch.ensure_contrast(0.76, 0.11, 215, "#141312", 65, "dark")',
      "```",
    },
    signs = {
      { line = 3, text = "┃", hl = "GitSignsAdd" },
      { line = 8, text = "┃", hl = "GitSignsChange" },
    },
    diagnostics = {},
  },
  {
    id = "ui",
    label = "Diff & UI Tokens",
    ft = "diff",
    lines = {
      "--- a/colors/tomorrow-night-eighties.lua",
      "+++ b/colors/tomorrow-night-modern.lua",
      "@@ -1,8 +1,9 @@",
      "-Normal  bg=#2d2d2d  fg=#cccccc  (legacy washed canvas)",
      "+Normal  bg=#111316  fg=#e0e3e5  (remastered OKLCH obsidian)",
      " Comment fg=muted italic  — quiet secondary metadata",
      "",
      "UI State Preview:",
      "  [Visual Selection]   selected region contrast check",
      "  [Search Match]       highlighted match   [IncSearch] active hit",
      "  [Popup Menu]         normal item         [PmenuSel]  focused item",
      "  [MatchParen]         fn(a, b) -> { ok: true }",
      "",
      "Diagnostic & Status Tokens:",
      "  ERROR    failed to parse palette token at line 42",
      "  WARN     chroma clamped to sRGB gamut ceiling",
      "  INFO     synced live palette from Rex pane",
      "  HINT     press <Tab> to cycle preview languages",
      "  OK       all APCA readability floors passing",
    },
    custom_hls = {
      { line = 3, col = 0, end_col = -1, hl = "DiffDelete" },
      { line = 4, col = 0, end_col = -1, hl = "DiffAdd" },
      { line = 5, col = 0, end_col = -1, hl = "Comment" },
      { line = 8, col = 2, end_col = 20, hl = "Visual" },
      { line = 9, col = 2, end_col = 16, hl = "Search" },
      { line = 9, col = 41, end_col = 52, hl = "IncSearch" },
      { line = 10, col = 2, end_col = 14, hl = "Pmenu" },
      { line = 10, col = 41, end_col = 51, hl = "PmenuSel" },
      { line = 11, col = 23, end_col = 24, hl = "MatchParen" },
      { line = 11, col = 29, end_col = 30, hl = "MatchParen" },
      { line = 14, col = 2, end_col = -1, hl = "DiagnosticVirtualTextError" },
      { line = 15, col = 2, end_col = -1, hl = "DiagnosticVirtualTextWarn" },
      { line = 16, col = 2, end_col = -1, hl = "DiagnosticVirtualTextInfo" },
      { line = 17, col = 2, end_col = -1, hl = "DiagnosticVirtualTextHint" },
      { line = 18, col = 2, end_col = -1, hl = "DiagnosticOk" },
    },
    signs = {
      { line = 4, text = "┃", hl = "GitSignsDelete" },
      { line = 5, text = "┃", hl = "GitSignsAdd" },
    },
    diagnostics = {},
  },
}

local SEV_HL = {
  error = { virt = "DiagnosticVirtualTextError", ul = "DiagnosticUnderlineError" },
  warn = { virt = "DiagnosticVirtualTextWarn", ul = "DiagnosticUnderlineWarn" },
  info = { virt = "DiagnosticVirtualTextInfo", ul = "DiagnosticUnderlineInfo" },
  hint = { virt = "DiagnosticVirtualTextHint", ul = "DiagnosticUnderlineHint" },
}

function M.apply_to_buffer(buf, spec)
  if not (buf and vim.api.nvim_buf_is_valid(buf) and spec) then
    return
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, spec.lines)
  vim.bo[buf].modifiable = false

  -- Trigger filetype / Treesitter highlighting cleanly
  vim.bo[buf].filetype = spec.ft
  pcall(vim.treesitter.start, buf)

  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

  for _, s in ipairs(spec.signs or {}) do
    local l0 = s.line - 1
    if l0 >= 0 and l0 < #spec.lines then
      vim.api.nvim_buf_set_extmark(buf, NS, l0, 0, {
        sign_text = s.text,
        sign_hl_group = s.hl,
      })
    end
  end

  for _, d in ipairs(spec.diagnostics or {}) do
    local l0 = d.line - 1
    local hl = SEV_HL[d.sev] or SEV_HL.info
    if l0 >= 0 and l0 < #spec.lines then
      local line_len = #spec.lines[d.line]
      vim.api.nvim_buf_set_extmark(buf, NS, l0, math.min(d.col, line_len), {
        end_col = math.min(d.end_col, line_len),
        hl_group = hl.ul,
        virt_text = { { "  " .. d.msg, hl.virt } },
        virt_text_pos = "eol",
      })
    end
  end

  for _, ch in ipairs(spec.custom_hls or {}) do
    local l0 = ch.line
    if l0 >= 0 and l0 < #spec.lines then
      local end_col = ch.end_col == -1 and #spec.lines[l0 + 1] or math.min(ch.end_col, #spec.lines[l0 + 1])
      vim.api.nvim_buf_set_extmark(buf, NS, l0, ch.col, {
        end_col = end_col,
        hl_group = ch.hl,
        hl_eol = ch.end_col == -1,
      })
    end
  end
end

return M
