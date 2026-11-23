-- Tasteful OKLCH palette synthesizer & retro-theme remastering engine.
local oklch = require("themenav.oklch")

local M = {}

local function clamp(x, lo, hi)
  if x < lo then
    return lo
  end
  if x > hi then
    return hi
  end
  return x
end

M.HARMONIES = { "analogous", "mono", "split", "triadic", "editorial" }
M.RESTRAINTS = { "minimal", "balanced", "expressive" }

function M.default_state(preset)
  local d = (preset and preset.defaults) or {}
  local polarity = (preset and preset.polarity) or "dark"
  local default_tint_hue = d.tint_hue
  local default_tint_strength = d.tint_strength

  if preset and preset.mode == "seed" and preset.seed and preset.seed.bg then
    local _, bg_c, bg_h = oklch.hex_to_oklch(preset.seed.bg)
    default_tint_hue = default_tint_hue or math.floor(bg_h + 0.5)
    default_tint_strength = default_tint_strength or clamp(bg_c, 0, 0.024)
  end

  return {
    mode = (preset and preset.mode) or "seed",
    preset_id = (preset and preset.id) or "merino-dark",
    preset_name = (preset and preset.name) or "Merino Dark",
    seed = preset and preset.seed or nil,
    polarity = polarity,
    depth = d.depth or 0.0,
    contrast = d.contrast or 1.04,
    chroma = d.chroma or 0.95,
    hue_shift = d.hue_shift or (preset and preset.mode == "studio" and 210 or 0),
    tint_hue = default_tint_hue or (polarity == "light" and 75 or 245),
    tint_strength = default_tint_strength or (polarity == "light" and 0.012 or 0.008),
    harmony = d.harmony or "analogous",
    restraint = d.restraint or "balanced",
    italics = d.italics ~= false,
  }
end

--- Remaster a single seed color into the target polarity, lightness band, chroma budget, and hue shift.
local function remaster_accent(hex, state, bg_hex, target_L, min_lc)
  local orig_L, orig_C, orig_H = oklch.hex_to_oklch(hex)
  local H = oklch.wrap_hue(orig_H + state.hue_shift)

  -- Preserve the color's relative vividness from its original lightness, then scale by chroma budget.
  local orig_ceil = math.max(oklch.max_chroma(orig_L, orig_H), 0.04)
  local rel_c = clamp(orig_C / orig_ceil, 0.14, 0.88)
  local target_rel = clamp(rel_c * state.chroma, 0.0, 0.92)

  -- Blend original lightness toward a perceptually even target_L so accents feel cohesive.
  local L
  if state.polarity == "dark" then
    local remapped = orig_L < 0.55 and (1.18 - orig_L) or orig_L
    L = clamp(target_L * 0.72 + remapped * 0.28, 0.60, 0.88)
  else
    local remapped = orig_L > 0.62 and (1.06 - orig_L) or orig_L
    L = clamp(target_L * 0.72 + remapped * 0.28, 0.34, 0.58)
  end

  local C = math.min(oklch.max_chroma(L, H) * target_rel, state.polarity == "dark" and 0.155 or 0.175)
  local final_hex = oklch.ensure_contrast(L, C, H, bg_hex, min_lc, state.polarity)
  return final_hex
end

--- Compute harmony accent hues in Studio mode from a primary hue.
local function studio_hues(primary_h, harmony)
  local h = oklch.wrap_hue(primary_h)
  if harmony == "mono" then
    return {
      a1 = h,
      a2 = oklch.wrap_hue(h + 16),
      a3 = oklch.wrap_hue(h - 14),
      a4 = oklch.wrap_hue(h + 32),
      muted_secondary = true,
    }
  elseif harmony == "analogous" then
    return {
      a1 = h,
      a2 = oklch.wrap_hue(h + 38),
      a3 = oklch.wrap_hue(h - 34),
      a4 = oklch.wrap_hue(h + 74),
    }
  elseif harmony == "split" then
    return {
      a1 = h,
      a2 = oklch.wrap_hue(h + 150),
      a3 = oklch.wrap_hue(h + 210),
      a4 = oklch.wrap_hue(h + 30),
    }
  elseif harmony == "triadic" then
    return {
      a1 = h,
      a2 = oklch.wrap_hue(h + 120),
      a3 = oklch.wrap_hue(h + 240),
      a4 = oklch.wrap_hue(h + 60),
    }
  else -- editorial (warm/cool balanced spread like Flexoki/Merino)
    return {
      a1 = h,
      a2 = oklch.wrap_hue(h + 85),
      a3 = oklch.wrap_hue(h + 175),
      a4 = oklch.wrap_hue(h - 55),
    }
  end
end

local function make_studio_color(L, rel_c, H, bg_hex, min_lc, polarity, max_c)
  local C = math.min(oklch.max_chroma(L, H) * clamp(rel_c, 0, 0.92), max_c or 0.15)
  return oklch.ensure_contrast(L, C, H, bg_hex, min_lc, polarity)
end

--- Build a complete semantic Neovim + ANSI palette from the current navigator state.
function M.build(state)
  local is_dark = state.polarity == "dark"
  local th = oklch.wrap_hue(state.tint_hue)
  local tc = clamp(state.tint_strength, 0, 0.032)
  local contrast = clamp(state.contrast, 0.70, 1.32)

  -- 1. Neutral surface ramp (one single tint hue -> zero hue drift across the UI)
  local base_bg_L
  if state.mode == "seed" and state.seed and state.seed.bg then
    local seed_L = oklch.hex_to_oklch(state.seed.bg)
    local seed_is_dark = seed_L <= 0.6
    if seed_is_dark == is_dark then
      base_bg_L = seed_L
    else
      -- Flip polarity cleanly across OKLCH lightness
      base_bg_L = is_dark and clamp(1.13 - seed_L, 0.15, 0.25) or clamp(1.13 - seed_L, 0.91, 0.98)
    end
  else
    base_bg_L = is_dark and 0.195 or 0.962
  end

  local bg_L = is_dark and clamp(base_bg_L + state.depth, 0.11, 0.34) or clamp(base_bg_L + state.depth, 0.84, 0.992)

  local bg = oklch.oklch_to_hex(bg_L, tc, th)
  local bg_alt = is_dark and oklch.oklch_to_hex(clamp(bg_L - 0.025, 0.08, 0.32), tc * 0.9, th)
    or oklch.oklch_to_hex(clamp(bg_L - 0.028, 0.80, 0.97), tc * 1.1, th)
  local bg_float = is_dark and oklch.oklch_to_hex(clamp(bg_L + 0.036, 0.14, 0.40), tc * 1.15, th)
    or oklch.oklch_to_hex(clamp(bg_L - 0.022, 0.80, 0.975), tc * 1.15, th)
  local bg_line = is_dark and oklch.oklch_to_hex(clamp(bg_L + 0.044, 0.15, 0.41), tc * 1.1, th)
    or oklch.oklch_to_hex(clamp(bg_L - 0.034, 0.78, 0.96), tc * 1.1, th)
  local bg_sel = is_dark and oklch.oklch_to_hex(clamp(bg_L + 0.095, 0.21, 0.48), tc * 1.6, th)
    or oklch.oklch_to_hex(clamp(bg_L - 0.082, 0.72, 0.92), tc * 1.6, th)
  local border = is_dark and oklch.oklch_to_hex(clamp(bg_L + 0.13, 0.25, 0.52), tc * 1.2, th)
    or oklch.oklch_to_hex(clamp(bg_L - 0.12, 0.68, 0.88), tc * 1.2, th)

  -- 2. Neutral ink ramp with APCA contrast floors
  local fg_target_lc = clamp(82 * contrast, 68, 98)
  local subtle_target_lc = clamp(56 * contrast, 46, 72)
  local muted_target_lc = clamp(39 * contrast, 32, 52)

  local fg_L = is_dark and clamp(0.84 + (contrast - 1.0) * 0.28, 0.76, 0.96)
    or clamp(0.27 - (contrast - 1.0) * 0.22, 0.14, 0.36)
  local subtle_L = is_dark and clamp(fg_L - 0.14, 0.60, 0.82) or clamp(fg_L + 0.17, 0.34, 0.52)
  local muted_L = is_dark and clamp(bg_L + 0.33 * contrast, 0.45, 0.65) or clamp(bg_L - 0.34 * contrast, 0.46, 0.66)
  local dim_L = is_dark and clamp(bg_L + 0.20, 0.32, 0.50) or clamp(bg_L - 0.19, 0.64, 0.82)

  local fg = oklch.ensure_contrast(fg_L, tc * 0.75, th, bg, fg_target_lc, state.polarity)
  local fg_subtle = oklch.ensure_contrast(subtle_L, tc * 0.85, th, bg, subtle_target_lc, state.polarity)
  local fg_muted = oklch.ensure_contrast(muted_L, tc * 0.80, th, bg, muted_target_lc, state.polarity)
  local fg_dim = oklch.oklch_to_hex(dim_L, tc * 0.7, th)

  -- 3. Accent & semantic colors
  local accent_L = is_dark and clamp(0.76 + (contrast - 1.0) * 0.16, 0.66, 0.86)
    or clamp(0.47 - (contrast - 1.0) * 0.14, 0.36, 0.56)
  local accent_min_lc = clamp(62 * contrast, 52, 78)
  local status_min_lc = clamp(60 * contrast, 52, 76)

  local red, orange, yellow, green, cyan, blue, purple
  if state.mode == "seed" and state.seed then
    local s = state.seed
    red = remaster_accent(s.red or "#e06c75", state, bg, accent_L - (is_dark and 0.02 or 0.0), accent_min_lc)
    orange = remaster_accent(s.orange or "#e59e67", state, bg, accent_L, accent_min_lc)
    yellow = remaster_accent(s.yellow or "#e5c07b", state, bg, accent_L + (is_dark and 0.03 or -0.02), accent_min_lc)
    green = remaster_accent(s.green or "#8fc98f", state, bg, accent_L, accent_min_lc)
    cyan = remaster_accent(s.cyan or "#66c2cd", state, bg, accent_L, accent_min_lc)
    blue = remaster_accent(s.blue or "#6ea8fe", state, bg, accent_L, accent_min_lc)
    purple = remaster_accent(s.purple or "#c099ff", state, bg, accent_L, accent_min_lc)
  else
    -- Studio procedural OKLCH harmony
    local hs = studio_hues(state.hue_shift, state.harmony)
    local base_rel = clamp(0.46 * state.chroma, 0.0, 0.88)
    local sec_rel = hs.muted_secondary and (base_rel * 0.32) or (base_rel * 0.85)
    local max_c = is_dark and 0.145 or 0.165

    blue = make_studio_color(accent_L, base_rel, hs.a1, bg, accent_min_lc, state.polarity, max_c)
    green = make_studio_color(accent_L, sec_rel, hs.a2, bg, accent_min_lc, state.polarity, max_c)
    purple = make_studio_color(accent_L, sec_rel, hs.a3, bg, accent_min_lc, state.polarity, max_c)
    cyan = make_studio_color(accent_L, sec_rel * 0.9, hs.a4, bg, accent_min_lc, state.polarity, max_c)
    orange =
      make_studio_color(accent_L, sec_rel * 0.92, oklch.wrap_hue(hs.a2 + 24), bg, accent_min_lc, state.polarity, max_c)
    yellow = make_studio_color(
      accent_L + (is_dark and 0.03 or -0.02),
      sec_rel * 0.82,
      oklch.wrap_hue(hs.a2 + 44),
      bg,
      accent_min_lc,
      state.polarity,
      max_c
    )
    red = make_studio_color(
      accent_L - 0.02,
      clamp(0.50 * state.chroma, 0.18, 0.85),
      22,
      bg,
      status_min_lc,
      state.polarity,
      max_c
    )
  end

  -- Harmonized status colors (keep semantic hue landmarks intact even when hue_shift moves syntax!)
  local status_rel = clamp(0.52 * state.chroma, 0.25, 0.85)
  local max_sc = is_dark and 0.15 or 0.17
  local err_col = state.mode == "seed" and state.hue_shift == 0 and red
    or make_studio_color(accent_L - 0.02, status_rel, 22, bg, status_min_lc, state.polarity, max_sc)
  local warn_col = state.mode == "seed" and state.hue_shift == 0 and yellow
    or make_studio_color(
      accent_L + (is_dark and 0.02 or -0.03),
      status_rel * 0.9,
      82,
      bg,
      status_min_lc,
      state.polarity,
      max_sc
    )
  local ok_col = state.mode == "seed" and state.hue_shift == 0 and green
    or make_studio_color(accent_L, status_rel * 0.88, 145, bg, status_min_lc, state.polarity, max_sc)
  local info_col = state.mode == "seed" and state.hue_shift == 0 and blue
    or make_studio_color(accent_L, status_rel * 0.88, 228, bg, status_min_lc, state.polarity, max_sc)
  local hint_col = state.mode == "seed" and state.hue_shift == 0 and cyan
    or make_studio_color(accent_L, status_rel * 0.82, 192, bg, status_min_lc, state.polarity, max_sc)

  -- 4. Syntax roles governed by Restraint (Minimal / Balanced / Expressive)
  local accent = blue
  local accent2 = green
  local accent3 = purple
  local syn = {}

  if state.restraint == "minimal" then
    -- Ultra-calm Zenbones/Vesper/Alabaster discipline: almost all ink is neutral,
    -- only strings, definitions, and constants carry subtle color.
    syn.variable = fg
    syn.property = fg
    syn.parameter = fg_subtle
    syn.operator = fg_muted
    syn.punctuation = fg_muted
    syn.keyword = fg_subtle
    syn.func = accent
    syn.type = fg
    syn.string = accent2
    syn.constant = orange
    syn.number = orange
    syn.special = cyan
    syn.tag = accent
  elseif state.restraint == "balanced" then
    -- The 80/15/5 sweet spot (Merino / Poimandres / Flexoki):
    -- variables & punctuation stay neutral; functions, strings, keywords, types are distinct & calm.
    syn.variable = fg
    syn.property = oklch.mix(fg, cyan, 0.35)
    syn.parameter = fg
    syn.operator = fg_subtle
    syn.punctuation = fg_muted
    syn.keyword = accent3
    syn.func = accent
    syn.type = yellow
    syn.string = accent2
    syn.constant = orange
    syn.number = orange
    syn.special = cyan
    syn.tag = accent
  else -- expressive (Tomorrow Night / Base16 heritage, still contrast-balanced in OKLCH)
    syn.variable = red
    syn.property = cyan
    syn.parameter = orange
    syn.operator = cyan
    syn.punctuation = fg_subtle
    syn.keyword = purple
    syn.func = blue
    syn.type = yellow
    syn.string = green
    syn.constant = orange
    syn.number = orange
    syn.special = cyan
    syn.tag = red
  end

  local tint_mix = is_dark and 0.16 or 0.14
  local bg_sel_accent = oklch.mix(bg, accent, is_dark and 0.24 or 0.20)
  local border_focus = oklch.mix(border, accent, 0.55)

  -- 5. Full 16-color ANSI palette (for terminal_color_0..15 and Rex push/export)
  local function brighten(hex)
    local l, c, h = oklch.hex_to_oklch(hex)
    local nl = is_dark and clamp(l + 0.07, 0, 0.94) or clamp(l - 0.07, 0.15, 1)
    return oklch.oklch_to_hex(nl, c * 1.05, h)
  end

  local ansi = {
    [0] = is_dark and bg_line or fg,
    [1] = err_col,
    [2] = ok_col,
    [3] = warn_col,
    [4] = blue,
    [5] = purple,
    [6] = cyan,
    [7] = is_dark and fg_subtle or bg_line,
    [8] = fg_muted,
    [9] = brighten(err_col),
    [10] = brighten(ok_col),
    [11] = brighten(warn_col),
    [12] = brighten(blue),
    [13] = brighten(purple),
    [14] = brighten(cyan),
    [15] = is_dark and fg or fg_subtle,
  }

  local palette = {
    polarity = state.polarity,
    italics = state.italics,
    -- Surfaces
    bg = bg,
    bg_alt = bg_alt,
    bg_float = bg_float,
    bg_line = bg_line,
    bg_sel = bg_sel_accent,
    bg_sel_neutral = bg_sel,
    border = border,
    border_focus = border_focus,
    -- Ink
    fg = fg,
    fg_subtle = fg_subtle,
    fg_muted = fg_muted,
    fg_dim = fg_dim,
    -- Accents & Syntax
    accent = accent,
    accent2 = accent2,
    accent3 = accent3,
    cursor = accent,
    red = red,
    orange = orange,
    yellow = yellow,
    green = green,
    cyan = cyan,
    blue = blue,
    purple = purple,
    syn = syn,
    -- Status & Diffs
    error = err_col,
    warn = warn_col,
    ok = ok_col,
    info = info_col,
    hint = hint_col,
    error_bg = oklch.mix(bg, err_col, tint_mix),
    warn_bg = oklch.mix(bg, warn_col, tint_mix),
    ok_bg = oklch.mix(bg, ok_col, tint_mix),
    info_bg = oklch.mix(bg, info_col, tint_mix),
    diff_add_bg = oklch.mix(bg, ok_col, tint_mix),
    diff_change_bg = oklch.mix(bg, info_col, tint_mix * 0.85),
    diff_del_bg = oklch.mix(bg, err_col, tint_mix),
    diff_text_bg = oklch.mix(bg, info_col, tint_mix * 1.7),
    search_bg = oklch.mix(bg, warn_col, is_dark and 0.28 or 0.30),
    incsearch_bg = warn_col,
    -- ANSI
    ansi = ansi,
    -- Telemetry
    metrics = {
      apca_fg = math.floor(oklch.apca_abs(fg, bg) + 0.5),
      apca_comment = math.floor(oklch.apca_abs(fg_muted, bg) + 0.5),
      apca_accent = math.floor(oklch.apca_abs(accent, bg) + 0.5),
      bg_L = bg_L,
    },
  }

  return palette
end

return M
