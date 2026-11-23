-- Curated seed palettes (Rex, Merino, Retro Classics, Base16, Modern) and OKLCH Studio presets.
local oklch = require("themenav.oklch")

local M = {}

--- Convert a Base16 scheme table (base00..base0F, hex with or without '#') into a seed preset.
function M.from_base16(id, name, b, extra)
  local function norm(v, fallback)
    if type(v) ~= "string" then
      return fallback
    end
    v = v:gsub("^#", "")
    return "#" .. v:lower()
  end
  local bg = norm(b.base00, "#181818")
  local fg = norm(b.base05, "#d8d8d8")
  local bg_L = oklch.hex_to_oklch(bg)
  local preset = {
    id = id,
    name = name,
    category = (extra and extra.category) or "base16",
    mode = "seed",
    polarity = bg_L > 0.6 and "light" or "dark",
    seed = {
      bg = bg,
      bg_alt = norm(b.base01, nil),
      bg_sel = norm(b.base02, nil),
      comment = norm(b.base03, nil),
      fg_subtle = norm(b.base04, nil),
      fg = fg,
      red = norm(b.base08, "#e06c75"),
      orange = norm(b.base09, "#d19a66"),
      yellow = norm(b.base0A, "#e5c07b"),
      green = norm(b.base0B, "#98c379"),
      cyan = norm(b.base0C, "#56b6c2"),
      blue = norm(b.base0D, "#61afef"),
      purple = norm(b.base0E, "#c678dd"),
      brown = norm(b.base0F, "#be5046"),
    },
    defaults = extra and extra.defaults or nil,
  }
  return preset
end

--- Parse a Base16 YAML string (e.g. tinted-theming / classic scheme YAML) into a seed preset.
function M.from_base16_yaml(yaml_text)
  local b = {}
  local name = "Imported Base16"
  for line in (yaml_text .. "\n"):gmatch("([^\n]*)\n") do
    local sname = line:match("^scheme:%s*[\"']?([^\"'\r\n]+)[\"']?") or line:match("^name:%s*[\"']?([^\"'\r\n]+)[\"']?")
    if sname then
      name = sname:gsub("%s+$", "")
    end
    local key, val = line:match("^%s*(base0[%xA-F]):%s*[\"']?#?([%x]+)[\"']?")
    if key and val and #val == 6 then
      b[key:sub(1, 5) .. key:sub(6, 6):upper()] = "#" .. val:lower()
    end
  end
  if not b.base00 or not b.base05 then
    return nil, "Could not find base00/base05 in YAML"
  end
  local id = "b16-" .. name:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return M.from_base16(id, name, b, { category = "imported" })
end

--- Sample the currently active Neovim colorscheme into a remasterable seed preset.
function M.from_current_nvim(name)
  local function hl_hex(group, attr)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl and hl[attr] then
      return string.format("#%06x", hl[attr])
    end
    return nil
  end

  local bg = hl_hex("Normal", "bg") or (vim.o.background == "light" and "#f5f4f0" or "#18181b")
  local fg = hl_hex("Normal", "fg") or (vim.o.background == "light" and "#1c1c1e" or "#e4e4e7")
  local bg_L = oklch.hex_to_oklch(bg)

  return {
    id = "nvim-current",
    name = name or ("Sampled: " .. (vim.g.colors_name or "current")),
    category = "sampled",
    mode = "seed",
    polarity = bg_L > 0.6 and "light" or "dark",
    seed = {
      bg = bg,
      fg = fg,
      comment = hl_hex("Comment", "fg"),
      red = hl_hex("DiagnosticError", "fg") or vim.g.terminal_color_1 or "#e06c75",
      orange = hl_hex("Number", "fg") or hl_hex("Constant", "fg") or vim.g.terminal_color_11 or "#e59e67",
      yellow = hl_hex("DiagnosticWarn", "fg") or hl_hex("Type", "fg") or vim.g.terminal_color_3 or "#e5c07b",
      green = hl_hex("String", "fg") or vim.g.terminal_color_2 or "#8fc98f",
      cyan = hl_hex("Special", "fg") or hl_hex("Operator", "fg") or vim.g.terminal_color_6 or "#66c2cd",
      blue = hl_hex("Function", "fg") or vim.g.terminal_color_4 or "#6ea8fe",
      purple = hl_hex("Keyword", "fg") or hl_hex("Statement", "fg") or vim.g.terminal_color_5 or "#c099ff",
    },
  }
end

M.builtin = {
  -- === Rex / Merino Favorites ===
  {
    id = "merino-dark",
    name = "Merino Dark",
    category = "rex",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#141312",
      fg = "#e6e1d8",
      comment = "#7b756c",
      red = "#e07a72",
      orange = "#de9b68",
      yellow = "#d9be76",
      green = "#87ba8b",
      cyan = "#71b7b4",
      blue = "#7ea8d9",
      purple = "#b799d4",
    },
    defaults = { restraint = "balanced", tint_hue = 65, tint_strength = 0.008 },
  },
  {
    id = "merino-light",
    name = "Merino Light",
    category = "rex",
    mode = "seed",
    polarity = "light",
    seed = {
      bg = "#f6f2ea",
      fg = "#2a2723",
      comment = "#878074",
      red = "#b5403a",
      orange = "#b36228",
      yellow = "#94741d",
      green = "#3c7a48",
      cyan = "#2b7876",
      blue = "#34649c",
      purple = "#77529c",
    },
    defaults = { restraint = "balanced", tint_hue = 72, tint_strength = 0.012 },
  },

  -- === Remastered Retro Classics ===
  M.from_base16("tomorrow-night-eighties-modern", "Tomorrow Night Eighties (Remastered)", {
    base00 = "2d2d2d",
    base01 = "393939",
    base02 = "515151",
    base03 = "999999",
    base04 = "b4b7b4",
    base05 = "cccccc",
    base06 = "e0e0e0",
    base07 = "ffffff",
    base08 = "f2777a",
    base09 = "f99157",
    base0A = "ffcc66",
    base0B = "99cc99",
    base0C = "66cccc",
    base0D = "6699cc",
    base0E = "cc99cc",
    base0F = "a3685a",
  }, {
    category = "remaster",
    defaults = {
      depth = -0.11,
      contrast = 1.08,
      chroma = 0.92,
      tint_hue = 250,
      tint_strength = 0.006,
      restraint = "balanced",
    },
  }),
  M.from_base16("tomorrow-night-eighties", "Tomorrow Night Eighties (Original)", {
    base00 = "2d2d2d",
    base01 = "393939",
    base02 = "515151",
    base03 = "999999",
    base04 = "b4b7b4",
    base05 = "cccccc",
    base06 = "e0e0e0",
    base07 = "ffffff",
    base08 = "f2777a",
    base09 = "f99157",
    base0A = "ffcc66",
    base0B = "99cc99",
    base0C = "66cccc",
    base0D = "6699cc",
    base0E = "cc99cc",
    base0F = "a3685a",
  }, {
    category = "classic",
    defaults = { depth = 0, contrast = 1.0, chroma = 1.0, restraint = "expressive" },
  }),
  M.from_base16("tomorrow-night", "Tomorrow Night", {
    base00 = "1d1f21",
    base01 = "282a2e",
    base02 = "373b41",
    base03 = "969896",
    base04 = "b4b7b4",
    base05 = "c5c8c6",
    base06 = "e0e0e0",
    base07 = "ffffff",
    base08 = "cc6666",
    base09 = "de935f",
    base0A = "f0c674",
    base0B = "b5bd68",
    base0C = "8abeb7",
    base0D = "81a2be",
    base0E = "b294bb",
    base0F = "a3685a",
  }, {
    category = "classic",
    defaults = { depth = -0.05, contrast = 1.06, chroma = 0.95, restraint = "balanced" },
  }),
  M.from_base16("base16-default-dark", "Base16 Default Dark", {
    base00 = "181818",
    base01 = "282828",
    base02 = "383838",
    base03 = "585858",
    base04 = "b8b8b8",
    base05 = "d8d8d8",
    base06 = "e8e8e8",
    base07 = "f8f8f8",
    base08 = "ab4642",
    base09 = "dc9656",
    base0A = "f7ca88",
    base0B = "a1b56c",
    base0C = "86c1b9",
    base0D = "7cafc2",
    base0E = "ba8baf",
    base0F = "a16946",
  }, {
    category = "base16",
    defaults = { depth = -0.03, contrast = 1.06, chroma = 0.95, restraint = "balanced" },
  }),
  M.from_base16("base16-ocean", "Base16 Ocean", {
    base00 = "2b303b",
    base01 = "343d46",
    base02 = "4f5b66",
    base03 = "65737e",
    base04 = "a7adba",
    base05 = "c0c5ce",
    base06 = "dfe1e8",
    base07 = "eff1f5",
    base08 = "bf616a",
    base09 = "d08770",
    base0A = "ebcb8b",
    base0B = "a3be8c",
    base0C = "96b5b4",
    base0D = "8fa1b3",
    base0E = "b48ead",
    base0F = "ab7967",
  }, {
    category = "base16",
    defaults = {
      depth = -0.10,
      contrast = 1.08,
      chroma = 0.96,
      tint_hue = 248,
      tint_strength = 0.012,
      restraint = "balanced",
    },
  }),
  M.from_base16("base16-atelier-forest", "Base16 Atelier Forest", {
    base00 = "1b1918",
    base01 = "2c2421",
    base02 = "68615e",
    base03 = "766e6b",
    base04 = "9c9491",
    base05 = "a8a19f",
    base06 = "e6e2e0",
    base07 = "f1efee",
    base08 = "f22c40",
    base09 = "df5320",
    base0A = "c38418",
    base0B = "7b9726",
    base0C = "3d97b8",
    base0D = "407ee7",
    base0E = "6666ea",
    base0F = "c33ff3",
  }, {
    category = "base16",
    defaults = {
      depth = -0.04,
      contrast = 1.08,
      chroma = 0.80,
      tint_hue = 55,
      tint_strength = 0.008,
      restraint = "balanced",
    },
  }),

  -- === Modern Tasteful Benchmarks ===
  {
    id = "poimandres-noir",
    name = "Poimandres Noir (Remastered)",
    category = "remaster",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#0f1119",
      fg = "#e4f0fb",
      comment = "#7d85a6",
      red = "#ee82b5",
      orange = "#f2c89b",
      yellow = "#ede5a6",
      green = "#5de4c7",
      cyan = "#89ddff",
      blue = "#add7ff",
      purple = "#c4b2f5",
    },
    defaults = {
      depth = 0.0,
      contrast = 1.10,
      chroma = 0.96,
      tint_hue = 272,
      tint_strength = 0.016,
      restraint = "balanced",
    },
  },
  {
    id = "poimandres",
    name = "Poimandres (Original)",
    category = "modern",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#1b1e28",
      fg = "#e4f0fb",
      comment = "#767c9d",
      red = "#d0679d",
      orange = "#fffac2",
      yellow = "#fffac2",
      green = "#5de4c7",
      cyan = "#89ddff",
      blue = "#add7ff",
      purple = "#f087bd",
    },
    defaults = {
      depth = 0.0,
      contrast = 1.0,
      chroma = 0.95,
      tint_hue = 272,
      tint_strength = 0.018,
      restraint = "balanced",
    },
  },
  {
    id = "vesper",
    name = "Vesper",
    category = "modern",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#101010",
      fg = "#e0e0e0",
      comment = "#7e7e7e",
      red = "#ff8080",
      orange = "#ffc799",
      yellow = "#ffc799",
      green = "#99ffe4",
      cyan = "#99ffe4",
      blue = "#b8c4d9",
      purple = "#c4b5fd",
    },
    defaults = {
      depth = 0,
      contrast = 1.05,
      chroma = 0.92,
      tint_hue = 60,
      tint_strength = 0.003,
      restraint = "minimal",
    },
  },
  {
    id = "flexoki-dark",
    name = "Flexoki Dark",
    category = "modern",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#100f0f",
      fg = "#cecdc3",
      comment = "#6f6e69",
      red = "#d14d41",
      orange = "#da702c",
      yellow = "#d0a215",
      green = "#879a39",
      cyan = "#3aa99f",
      blue = "#4385be",
      purple = "#8b7ec8",
    },
    defaults = {
      depth = 0,
      contrast = 1.04,
      chroma = 0.96,
      tint_hue = 75,
      tint_strength = 0.006,
      restraint = "balanced",
    },
  },
  {
    id = "flexoki-light",
    name = "Flexoki Light",
    category = "modern",
    mode = "seed",
    polarity = "light",
    seed = {
      bg = "#fffcf0",
      fg = "#100f0f",
      comment = "#6f6e69",
      red = "#af3029",
      orange = "#bc5215",
      yellow = "#ad8301",
      green = "#66800b",
      cyan = "#24837b",
      blue = "#205ea6",
      purple = "#5e409d",
    },
    defaults = {
      depth = 0,
      contrast = 1.0,
      chroma = 0.95,
      tint_hue = 82,
      tint_strength = 0.015,
      restraint = "balanced",
    },
  },
  {
    id = "zenbones-dark",
    name = "Zenbones Dark",
    category = "modern",
    mode = "seed",
    polarity = "dark",
    seed = {
      bg = "#191919",
      fg = "#d5d9dc",
      comment = "#6e7378",
      red = "#de6e7c",
      orange = "#d6926c",
      yellow = "#d6b072",
      green = "#819b69",
      cyan = "#66a5ad",
      blue = "#6099c0",
      purple = "#b279a7",
    },
    defaults = {
      depth = -0.02,
      contrast = 1.02,
      chroma = 0.72,
      tint_hue = 240,
      tint_strength = 0.004,
      restraint = "minimal",
    },
  },

  -- === Pure Procedural OKLCH Studio Presets ===
  {
    id = "studio-warm-obsidian",
    name = "Studio: Warm Obsidian",
    category = "studio",
    mode = "studio",
    polarity = "dark",
    defaults = {
      depth = -0.02,
      contrast = 1.05,
      chroma = 0.85,
      hue_shift = 55,
      tint_hue = 65,
      tint_strength = 0.009,
      harmony = "analogous",
      restraint = "balanced",
    },
  },
  {
    id = "studio-ink-paper",
    name = "Studio: Ink & Paper",
    category = "studio",
    mode = "studio",
    polarity = "light",
    defaults = {
      depth = 0.0,
      contrast = 1.04,
      chroma = 0.82,
      hue_shift = 215,
      tint_hue = 78,
      tint_strength = 0.013,
      harmony = "editorial",
      restraint = "balanced",
    },
  },
  {
    id = "studio-cool-slate",
    name = "Studio: Cool Slate",
    category = "studio",
    mode = "studio",
    polarity = "dark",
    defaults = {
      depth = -0.03,
      contrast = 1.06,
      chroma = 0.88,
      hue_shift = 210,
      tint_hue = 250,
      tint_strength = 0.014,
      harmony = "analogous",
      restraint = "balanced",
    },
  },
  {
    id = "studio-monochrome-accent",
    name = "Studio: Monochrome + 1",
    category = "studio",
    mode = "studio",
    polarity = "dark",
    defaults = {
      depth = -0.04,
      contrast = 1.08,
      chroma = 0.90,
      hue_shift = 165,
      tint_hue = 240,
      tint_strength = 0.005,
      harmony = "mono",
      restraint = "minimal",
    },
  },
  {
    id = "studio-editorial-triadic",
    name = "Studio: Editorial Triadic",
    category = "studio",
    mode = "studio",
    polarity = "dark",
    defaults = {
      depth = -0.02,
      contrast = 1.06,
      chroma = 0.84,
      hue_shift = 32,
      tint_hue = 50,
      tint_strength = 0.007,
      harmony = "editorial",
      restraint = "expressive",
    },
  },
}

return M
