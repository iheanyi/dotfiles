-- Real-time floating Theme Navigator & OKLCH Studio panel + live multi-language specimen preview.
local generator = require("themenav.generator")
local highlights = require("themenav.highlights")
local oklch = require("themenav.oklch")
local presets = require("themenav.presets")
local rex = require("themenav.rex")
local specimens = require("themenav.specimens")

local M = {}

local NS = vim.api.nvim_create_namespace("themenav_ui")
local PANEL_WIDTH = 46
local DIAL_START_LINE = 3 -- 0-based line index where dial rows begin (hdr, swatches, rule)

local ctx = {
  buf = nil,
  win = nil,
  spec_buf = nil,
  spec_win = nil,
  spec_open = false,
  spec_idx = 1,
  all_presets = {},
  preset_idx = 1,
  state = nil,
  palette = nil,
  cursor_row = 1,
  rex_live_sync = false,
  original_colorscheme = nil,
  original_background = nil,
  original_sample = nil,
  saved_or_kept = false,
  debounce_timer = nil,
  rex_timer = nil,
  resize_augroup = nil,
  status_msg = nil,
}

local function clamp(x, lo, hi)
  if x < lo then
    return lo
  end
  if x > hi then
    return hi
  end
  return x
end

local function cycle_list(list, current, delta)
  local idx = 1
  for i, v in ipairs(list) do
    if v == current then
      idx = i
      break
    end
  end
  local next_idx = ((idx - 1 + delta) % #list) + 1
  return list[next_idx]
end

local function find_preset_index(id)
  for i, p in ipairs(ctx.all_presets) do
    if p.id == id then
      return i
    end
  end
  return 1
end

local function upsert_preset(preset)
  for i, p in ipairs(ctx.all_presets) do
    if p.id == preset.id then
      ctx.all_presets[i] = preset
      return i
    end
  end
  table.insert(ctx.all_presets, 1, preset)
  return 1
end

local function load_preset_list()
  ctx.all_presets = {}
  for _, p in ipairs(presets.builtin) do
    ctx.all_presets[#ctx.all_presets + 1] = p
  end
end

local function make_bar(val, lo, hi, width)
  local ratio = clamp((val - lo) / (hi - lo), 0, 1)
  local pos = math.floor(ratio * (width - 1) + 0.5)
  local left = string.rep("━", pos)
  local right = string.rep("─", (width - 1) - pos)
  return left .. "●" .. right
end

local function get_dials()
  local s = ctx.state
  local dials = {
    {
      id = "preset",
      label = "Preset",
      kind = "preset",
      display = function()
        local name = s.preset_name or s.preset_id
        if #name > 24 then
          name = name:sub(1, 23) .. "…"
        end
        return string.format("‹ %s ›", name)
      end,
      step = function(delta)
        ctx.preset_idx = ((ctx.preset_idx - 1 + delta) % #ctx.all_presets) + 1
        local p = ctx.all_presets[ctx.preset_idx]
        ctx.state = generator.default_state(p)
        ctx.status_msg = string.format("[%s] %s", p.category or "preset", p.name)
      end,
    },
    {
      id = "mode",
      label = "Engine",
      display = function()
        return s.mode == "studio" and "‹ OKLCH Studio ›" or "‹ Seed Remaster ›"
      end,
      step = function()
        s.mode = s.mode == "studio" and "seed" or "studio"
        if s.mode == "seed" and not s.seed then
          s.seed = presets.builtin[1].seed
        end
      end,
    },
    {
      id = "polarity",
      label = "Polarity",
      display = function()
        return s.polarity == "light" and "‹ Light ›" or "‹ Dark ›"
      end,
      step = function()
        s.polarity = s.polarity == "dark" and "light" or "dark"
      end,
    },
    {
      id = "depth",
      label = "Bg Depth",
      display = function()
        return string.format("%s %+.2f", make_bar(s.depth, -0.14, 0.14, 15), s.depth)
      end,
      step = function(delta, big)
        local inc = big and 0.03 or 0.01
        s.depth = clamp(s.depth + delta * inc, -0.14, 0.14)
      end,
    },
    {
      id = "contrast",
      label = "Contrast",
      display = function()
        return string.format("%s %.2fx", make_bar(s.contrast, 0.72, 1.30, 15), s.contrast)
      end,
      step = function(delta, big)
        local inc = big and 0.06 or 0.02
        s.contrast = clamp(s.contrast + delta * inc, 0.72, 1.30)
      end,
    },
    {
      id = "chroma",
      label = "Chroma",
      display = function()
        return string.format("%s %3d%%", make_bar(s.chroma, 0.0, 1.45, 15), math.floor(s.chroma * 100 + 0.5))
      end,
      step = function(delta, big)
        local inc = big and 0.12 or 0.04
        s.chroma = clamp(s.chroma + delta * inc, 0.0, 1.45)
      end,
    },
    {
      id = "hue_shift",
      label = s.mode == "studio" and "Accent Hue" or "Hue Shift",
      display = function()
        if s.mode == "studio" then
          local h = oklch.wrap_hue(s.hue_shift)
          return string.format("%s %3d°", make_bar(h, 0, 359, 15), math.floor(h + 0.5))
        end
        return string.format("%s %+4d°", make_bar(s.hue_shift, -180, 180, 15), math.floor(s.hue_shift + 0.5))
      end,
      step = function(delta, big)
        local inc = big and 18 or 5
        if s.mode == "studio" then
          s.hue_shift = oklch.wrap_hue(s.hue_shift + delta * inc)
        else
          s.hue_shift = clamp(s.hue_shift + delta * inc, -180, 180)
        end
      end,
    },
    {
      id = "tint_hue",
      label = "Tint Hue",
      display = function()
        local h = oklch.wrap_hue(s.tint_hue)
        return string.format("%s %3d°", make_bar(h, 0, 359, 15), math.floor(h + 0.5))
      end,
      step = function(delta, big)
        local inc = big and 20 or 6
        s.tint_hue = oklch.wrap_hue(s.tint_hue + delta * inc)
      end,
    },
    {
      id = "tint_strength",
      label = "Tint Amt",
      display = function()
        return string.format("%s %.3f", make_bar(s.tint_strength, 0.0, 0.030, 15), s.tint_strength)
      end,
      step = function(delta, big)
        local inc = big and 0.004 or 0.001
        s.tint_strength = clamp(s.tint_strength + delta * inc, 0.0, 0.030)
      end,
    },
    {
      id = "restraint",
      label = "Restraint",
      display = function()
        return string.format("‹ %s ›", s.restraint:sub(1, 1):upper() .. s.restraint:sub(2))
      end,
      step = function(delta)
        s.restraint = cycle_list(generator.RESTRAINTS, s.restraint, delta)
      end,
    },
  }

  if s.mode == "studio" then
    table.insert(dials, 10, {
      id = "harmony",
      label = "Harmony",
      display = function()
        return string.format("‹ %s ›", s.harmony:sub(1, 1):upper() .. s.harmony:sub(2))
      end,
      step = function(delta)
        s.harmony = cycle_list(generator.HARMONIES, s.harmony, delta)
      end,
    })
  end

  dials[#dials + 1] = {
    id = "italics",
    label = "Italics",
    display = function()
      return s.italics and "‹ On ›" or "‹ Off ›"
    end,
    step = function()
      s.italics = not s.italics
    end,
  }

  if rex.is_in_rex() then
    dials[#dials + 1] = {
      id = "rex_sync",
      label = "Rex Sync",
      display = function()
        return ctx.rex_live_sync and "‹ Live Push ›" or "‹ Off ›"
      end,
      step = function()
        ctx.rex_live_sync = not ctx.rex_live_sync
        if ctx.rex_live_sync and ctx.palette then
          rex.push_to_rex(ctx.palette)
        end
      end,
    }
  end

  return dials
end

local function update_panel_highlights(p)
  vim.api.nvim_set_hl(0, "ThemeNavNormal", { fg = p.fg, bg = p.bg_float })
  vim.api.nvim_set_hl(0, "ThemeNavBorder", { fg = p.border_focus, bg = p.bg_float })
  vim.api.nvim_set_hl(0, "ThemeNavTitle", { fg = p.accent, bg = p.bg_float, bold = true })
  vim.api.nvim_set_hl(0, "ThemeNavMuted", { fg = p.fg_muted, bg = p.bg_float })
  vim.api.nvim_set_hl(0, "ThemeNavActive", { fg = p.fg, bg = p.bg_sel, bold = true })
  vim.api.nvim_set_hl(0, "ThemeNavLabel", { fg = p.fg_subtle, bg = p.bg_float })
  vim.api.nvim_set_hl(0, "ThemeNavValue", { fg = p.accent, bg = p.bg_float })
  vim.api.nvim_set_hl(0, "ThemeNavOk", { fg = p.ok, bg = p.bg_float, bold = true })
  vim.api.nvim_set_hl(0, "ThemeNavWarn", { fg = p.warn, bg = p.bg_float, bold = true })

  local swatches = {
    p.bg,
    p.bg_line,
    p.bg_sel,
    p.fg_muted,
    p.fg,
    p.accent,
    p.accent2,
    p.accent3,
    p.yellow,
    p.orange,
    p.red,
    p.cyan,
  }
  for i, hex in ipairs(swatches) do
    vim.api.nvim_set_hl(0, "ThemeNavSwatch" .. i, { fg = hex, bg = p.bg_float })
  end
end

local function compute_layout(panel_line_count)
  local cols = vim.o.columns
  local lines = vim.o.lines
  local usable_lines = math.max(10, lines - 4)

  local panel_w = math.min(PANEL_WIDTH, math.max(36, cols - 4))
  local panel_h = math.min(panel_line_count, usable_lines)
  local panel_col = math.max(1, cols - panel_w - 2)
  local panel_row = 1

  local spec_cfg = nil
  if ctx.spec_open then
    local left_space = panel_col - 4
    if left_space >= 44 then
      -- Side-by-side: cap preview width at a readable 96 cols and anchor cleanly next to studio
      local spec_w = math.min(96, left_space)
      local spec_col = math.max(2, panel_col - spec_w - 3)
      local spec_h = math.min(math.max(panel_h, 30), usable_lines)
      spec_cfg = {
        relative = "editor",
        row = panel_row,
        col = spec_col,
        width = spec_w,
        height = spec_h,
      }
    elseif usable_lines - panel_h - 3 >= 10 then
      -- Narrow terminal fallback: stack specimen directly beneath the studio panel
      spec_cfg = {
        relative = "editor",
        row = panel_row + panel_h + 2,
        col = panel_col,
        width = panel_w,
        height = math.min(24, usable_lines - panel_h - 3),
      }
    end
  end

  return {
    panel = {
      relative = "editor",
      row = panel_row,
      col = panel_col,
      width = panel_w,
      height = panel_h,
    },
    spec = spec_cfg,
  }
end

local function specimen_title()
  local spec = specimens.list[ctx.spec_idx]
  local tabs = {}
  for i, item in ipairs(specimens.list) do
    if i == ctx.spec_idx then
      tabs[#tabs + 1] = "[" .. item.id .. "]"
    else
      tabs[#tabs + 1] = item.id
    end
  end
  return string.format(" Preview: %s  (%s) ", spec.label, table.concat(tabs, " "))
end

local function close_specimen()
  if ctx.spec_win and vim.api.nvim_win_is_valid(ctx.spec_win) then
    vim.api.nvim_win_close(ctx.spec_win, true)
  end
  ctx.spec_win = nil
  ctx.spec_buf = nil
end

local function sync_specimen_window(spec_cfg)
  if not ctx.spec_open or not spec_cfg then
    close_specimen()
    return
  end

  local spec = specimens.list[ctx.spec_idx]
  if not (ctx.spec_buf and vim.api.nvim_buf_is_valid(ctx.spec_buf)) then
    ctx.spec_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[ctx.spec_buf].buftype = "nofile"
    vim.bo[ctx.spec_buf].bufhidden = "wipe"
    vim.bo[ctx.spec_buf].swapfile = false
  end

  specimens.apply_to_buffer(ctx.spec_buf, spec)

  local title = specimen_title()
  if #title > spec_cfg.width - 2 then
    title = " Preview: " .. spec.label .. " "
  end

  if ctx.spec_win and vim.api.nvim_win_is_valid(ctx.spec_win) then
    vim.api.nvim_win_set_config(
      ctx.spec_win,
      vim.tbl_extend("force", spec_cfg, {
        border = "rounded",
        title = title,
        title_pos = "left",
        zindex = 55,
      })
    )
  else
    ctx.spec_win = vim.api.nvim_open_win(
      ctx.spec_buf,
      false,
      vim.tbl_extend("force", spec_cfg, {
        focusable = false,
        border = "rounded",
        title = title,
        title_pos = "left",
        zindex = 55,
      })
    )
    vim.wo[ctx.spec_win].number = true
    vim.wo[ctx.spec_win].relativenumber = false
    vim.wo[ctx.spec_win].signcolumn = "yes:1"
    vim.wo[ctx.spec_win].cursorline = true
    vim.wo[ctx.spec_win].colorcolumn = ""
    vim.wo[ctx.spec_win].wrap = false
    vim.wo[ctx.spec_win].foldenable = false
    vim.wo[ctx.spec_win].winhl = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle"
    pcall(vim.api.nvim_win_set_cursor, ctx.spec_win, { math.min(14, #spec.lines), 0 })
  end
end

local function render()
  if not (ctx.buf and vim.api.nvim_buf_is_valid(ctx.buf) and ctx.palette) then
    return
  end

  local p = ctx.palette
  local m = p.metrics
  local dials = get_dials()
  ctx.cursor_row = clamp(ctx.cursor_row, 1, #dials)

  local panel_w = math.min(PANEL_WIDTH, math.max(36, vim.o.columns - 4))
  local lines = {}
  local hl_spans = {} -- { line_0, col_start, col_end, group, hl_eol }

  local function add_line(text, spans)
    local lnum = #lines
    lines[#lines + 1] = text
    if spans then
      for _, sp in ipairs(spans) do
        hl_spans[#hl_spans + 1] = { lnum, sp[1], sp[2], sp[3], sp[4] }
      end
    end
  end

  -- Header + live APCA readout
  local fg_grade = m.apca_fg >= 75 and "ThemeNavOk" or "ThemeNavWarn"
  local cmt_grade = m.apca_comment >= 34 and "ThemeNavOk" or "ThemeNavWarn"
  local acc_grade = m.apca_accent >= 58 and "ThemeNavOk" or "ThemeNavWarn"
  local hdr = string.format(" BG %s   FG %d  CMT %d  ACC %d", p.bg, m.apca_fg, m.apca_comment, m.apca_accent)
  local fg_pos = hdr:find("FG ")
  local cmt_pos = hdr:find("CMT ")
  local acc_pos = hdr:find("ACC ")
  add_line(hdr, {
    { 0, fg_pos - 1, "ThemeNavMuted" },
    { fg_pos - 1, cmt_pos - 2, fg_grade },
    { cmt_pos - 1, acc_pos - 2, cmt_grade },
    { acc_pos - 1, #hdr, acc_grade },
  })

  -- Live 12-chip color swatch bar (scales to fit narrow terminals cleanly)
  local chip_count = panel_w >= 40 and 12 or 10
  local swatch_line = " "
  local swatch_spans = {}
  for i = 1, chip_count do
    local s_col = #swatch_line
    swatch_line = swatch_line .. "██ "
    swatch_spans[#swatch_spans + 1] = { s_col, s_col + 6, "ThemeNavSwatch" .. i }
  end
  add_line(swatch_line, swatch_spans)
  add_line(" " .. string.rep("─", panel_w - 2), { { 0, -1, "ThemeNavMuted" } })

  -- Interactive dial rows
  for i, dial in ipairs(dials) do
    local active = i == ctx.cursor_row
    local marker = active and "▸ " or "  "
    local label = string.format("%-11s", dial.label)
    local val = dial.display()
    local line = marker .. label .. val
    if active then
      add_line(line, { { 0, -1, "ThemeNavActive", true } })
    else
      local label_end = #marker + #label
      add_line(line, {
        { 0, label_end, "ThemeNavLabel" },
        { label_end, -1, "ThemeNavValue" },
      })
    end
  end

  add_line(" " .. string.rep("─", panel_w - 2), { { 0, -1, "ThemeNavMuted" } })
  add_line(" h/l scrub  H/L fast  [/] preset  p pick", { { 0, -1, "ThemeNavMuted" } })
  add_line(" s preview  Tab lang  r rex  c sample", { { 0, -1, "ThemeNavMuted" } })
  add_line(" m dark/lt  z random  0 reset  x push", { { 0, -1, "ThemeNavMuted" } })
  add_line(" w export   ⏎ keep    q cancel", { { 0, -1, "ThemeNavMuted" } })
  if ctx.status_msg then
    local msg = ctx.status_msg
    local max_len = panel_w - 2
    if #msg > max_len then
      msg = msg:sub(1, max_len - 1) .. "…"
    end
    add_line(" " .. msg, { { 0, -1, "ThemeNavTitle" } })
  end

  local layout = compute_layout(#lines)

  if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
    vim.api.nvim_win_set_config(
      ctx.win,
      vim.tbl_extend("force", layout.panel, {
        border = "rounded",
        title = " Theme Studio (OKLCH) ",
        title_pos = "center",
        zindex = 60,
      })
    )
  end

  sync_specimen_window(layout.spec)

  vim.bo[ctx.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  vim.bo[ctx.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(ctx.buf, NS, 0, -1)
  for _, sp in ipairs(hl_spans) do
    vim.api.nvim_buf_set_extmark(ctx.buf, NS, sp[1], sp[2], {
      end_col = sp[3] == -1 and #lines[sp[1] + 1] or sp[3],
      hl_group = sp[4],
      hl_eol = sp[5] == true,
    })
  end

  -- Keep window cursor aligned on the active dial so short terminals scroll cleanly
  if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
    local target_line = clamp(DIAL_START_LINE + ctx.cursor_row, 1, #lines)
    pcall(vim.api.nvim_win_set_cursor, ctx.win, { target_line, 0 })
  end
end

local function push_rex_debounced()
  if not (ctx.rex_live_sync and ctx.palette and rex.is_in_rex()) then
    return
  end
  if not ctx.rex_timer then
    ctx.rex_timer = vim.uv.new_timer()
  end
  ctx.rex_timer:stop()
  ctx.rex_timer:start(
    80,
    0,
    vim.schedule_wrap(function()
      if ctx.palette then
        rex.push_to_rex(ctx.palette)
      end
    end)
  )
end

local function apply_live(notify_cs)
  ctx.palette = generator.build(ctx.state)
  highlights.apply(ctx.palette, {
    name = "themenav-live",
    notify_colorscheme = notify_cs ~= false,
  })
  update_panel_highlights(ctx.palette)
  render()
  push_rex_debounced()
end

local function schedule_apply()
  if not ctx.debounce_timer then
    ctx.debounce_timer = vim.uv.new_timer()
  end
  ctx.debounce_timer:stop()
  ctx.debounce_timer:start(
    16,
    0,
    vim.schedule_wrap(function()
      apply_live(true)
    end)
  )
end

function M.get_current()
  return ctx.state, ctx.palette
end

function M.apply_preset_by_id(id)
  if #ctx.all_presets == 0 then
    load_preset_list()
  end
  local idx = find_preset_index(id)
  local preset = ctx.all_presets[idx]
  if not preset then
    return false
  end
  ctx.preset_idx = idx
  ctx.state = generator.default_state(preset)
  ctx.palette = generator.build(ctx.state)
  highlights.apply(ctx.palette, { name = preset.id, clear = true })
  return true, preset
end

function M.export_current(slug_override)
  if not (ctx.state and ctx.palette) then
    vim.notify("themenav: no active theme to export", vim.log.levels.WARN)
    return
  end

  local default_slug = (ctx.state.preset_id or "custom-theme")
    :gsub("^studio%-", "")
    :gsub("^rex%-live$", "rex-merino")
    :lower()
    :gsub("[^%w_-]+", "-")

  local function do_write(raw_name)
    if not raw_name or raw_name:gsub("%s+", "") == "" then
      return
    end
    local slug = raw_name:lower():gsub("[^%w_-]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    if slug == "" then
      return
    end

    local config_colors = vim.fn.stdpath("config") .. "/colors"
    local dotfiles_colors = vim.fn.expand("~/development/dotfiles/colors")
    local has_dotfiles = vim.fn.isdirectory(vim.fn.expand("~/development/dotfiles")) == 1

    vim.fn.mkdir(config_colors, "p")
    local lua_src = highlights.export_neovim_lua(slug, ctx.palette, ctx.state)
    local nvim_target = config_colors .. "/" .. slug .. ".lua"

    if has_dotfiles then
      vim.fn.mkdir(dotfiles_colors, "p")
      local repo_target = dotfiles_colors .. "/" .. slug .. ".lua"
      local f = assert(io.open(repo_target, "w"))
      f:write(lua_src)
      f:close()
      pcall(vim.uv.fs_unlink, nvim_target)
      local ok_link = pcall(vim.uv.fs_symlink, repo_target, nvim_target)
      if not ok_link then
        local f2 = assert(io.open(nvim_target, "w"))
        f2:write(lua_src)
        f2:close()
      end
    else
      local f = assert(io.open(nvim_target, "w"))
      f:write(lua_src)
      f:close()
    end

    local theme_title = rex.slug_to_title(slug)
    local rex_dir = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/rex/themes"
    local ghostty_dir = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/ghostty/themes"
    local dotfiles_rex_themes = vim.fn.expand("~/development/dotfiles/rex/themes")
    local rex_conf = rex.format_ghostty_conf(theme_title, ctx.palette)
    vim.fn.mkdir(rex_dir, "p")
    vim.fn.mkdir(ghostty_dir, "p")
    local rex_target = rex_dir .. "/" .. theme_title
    local ghostty_target = ghostty_dir .. "/" .. theme_title

    local import_path = rex_target
    if has_dotfiles then
      vim.fn.mkdir(dotfiles_rex_themes, "p")
      local repo_rex_target = dotfiles_rex_themes .. "/" .. theme_title
      local rf = assert(io.open(repo_rex_target, "w"))
      rf:write(rex_conf)
      rf:close()
      import_path = repo_rex_target
      for _, dest in ipairs({ rex_target, ghostty_target }) do
        pcall(vim.uv.fs_unlink, dest)
        local ok_rlink = pcall(vim.uv.fs_symlink, repo_rex_target, dest)
        if not ok_rlink then
          local rf2 = assert(io.open(dest, "w"))
          rf2:write(rex_conf)
          rf2:close()
        end
      end
    else
      local rf = assert(io.open(rex_target, "w"))
      rf:write(rex_conf)
      rf:close()
    end

    ctx.saved_or_kept = true
    vim.g.colors_name = slug
    ctx.status_msg = "Exported :colorscheme " .. slug
    render()

    if rex.is_in_rex() then
      rex.import_into_rex(import_path, function(ok, err)
        if ok then
          ctx.status_msg = "Exported & imported into Rex: " .. theme_title
          render()
          vim.notify(
            string.format(
              "Exported %s & imported into Rex\n  Neovim: %s\n  Rex/Ghostty: %s",
              theme_title,
              nvim_target,
              import_path
            ),
            vim.log.levels.INFO
          )
        else
          vim.notify(
            string.format(
              "Exported %s (Rex import skipped: %s)\n  Neovim: %s\n  Rex/Ghostty: %s",
              slug,
              err or "unknown error",
              nvim_target,
              import_path
            ),
            vim.log.levels.WARN
          )
        end
      end)
    else
      vim.notify(
        string.format("Exported %s\n  Neovim: %s\n  Rex/Ghostty: %s", slug, nvim_target, import_path),
        vim.log.levels.INFO
      )
    end
  end

  if slug_override and slug_override ~= "" then
    do_write(slug_override)
  else
    vim.ui.input({ prompt = "Export theme name (slug): ", default = default_slug }, do_write)
  end
end

function M.sync_from_rex(silent)
  if #ctx.all_presets == 0 then
    load_preset_list()
  end
  ctx.status_msg = "Querying Rex live palette…"
  render()
  rex.read_live_palette(function(preset, err)
    if not preset then
      ctx.status_msg = err or "Rex palette unavailable"
      render()
      if not silent then
        vim.notify("themenav: " .. ctx.status_msg, vim.log.levels.WARN)
      end
      return
    end
    ctx.preset_idx = upsert_preset(preset)
    ctx.state = generator.default_state(preset)
    ctx.status_msg = "Synced " .. preset.name
    apply_live(true)
    if not (ctx.win and vim.api.nvim_win_is_valid(ctx.win)) and not silent then
      vim.notify("themenav: synced " .. preset.name .. " (" .. ctx.palette.bg .. ")", vim.log.levels.INFO)
    end
  end)
end

function M.register_preset(preset)
  if #ctx.all_presets == 0 then
    load_preset_list()
  end
  return upsert_preset(preset)
end

local function close_panel(restore)
  if ctx.resize_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, ctx.resize_augroup)
    ctx.resize_augroup = nil
  end
  if ctx.debounce_timer then
    pcall(function()
      ctx.debounce_timer:stop()
      ctx.debounce_timer:close()
    end)
    ctx.debounce_timer = nil
  end
  if ctx.rex_timer then
    pcall(function()
      ctx.rex_timer:stop()
      ctx.rex_timer:close()
    end)
    ctx.rex_timer = nil
  end

  close_specimen()

  if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
    vim.api.nvim_win_close(ctx.win, true)
  end
  ctx.win = nil
  ctx.buf = nil

  if restore and not ctx.saved_or_kept then
    if ctx.original_background then
      vim.o.background = ctx.original_background
    end
    if ctx.original_colorscheme and ctx.original_colorscheme ~= "" and ctx.original_colorscheme ~= "themenav-live" then
      pcall(vim.cmd.colorscheme, ctx.original_colorscheme)
    end
  end
end

local function randomize_studio()
  math.randomseed(os.time() + math.floor(vim.uv.hrtime() % 100000))
  local is_light = ctx.state.polarity == "light"
  local accent_h = math.random(0, 359)
  local harmonies = generator.HARMONIES
  local restraints = { "minimal", "balanced", "balanced", "expressive" }
  local tint_h = math.random() < 0.5 and math.random(48, 84) or math.random(220, 265)

  ctx.state.mode = "studio"
  ctx.state.preset_id = "studio-custom"
  ctx.state.preset_name = "Studio Custom"
  ctx.state.hue_shift = accent_h
  ctx.state.tint_hue = tint_h
  ctx.state.tint_strength = is_light and (0.006 + math.random() * 0.010) or (0.004 + math.random() * 0.012)
  ctx.state.depth = is_light and (-0.02 + math.random() * 0.03) or (-0.06 + math.random() * 0.06)
  ctx.state.contrast = 1.0 + math.random() * 0.14
  ctx.state.chroma = 0.72 + math.random() * 0.34
  ctx.state.harmony = harmonies[math.random(1, #harmonies)]
  ctx.state.restraint = restraints[math.random(1, #restraints)]
  ctx.status_msg = string.format("Studio %s · H%d°", ctx.state.harmony, accent_h)
  apply_live(true)
end

local function open_preset_picker()
  local items = {}
  for _, p in ipairs(ctx.all_presets) do
    items[#items + 1] = p
  end
  vim.ui.select(items, {
    prompt = "Select theme seed / preset:",
    format_item = function(item)
      return string.format("[%-8s] %s (%s)", item.category or "seed", item.name, item.polarity or "dark")
    end,
  }, function(choice)
    if not choice then
      return
    end
    ctx.preset_idx = find_preset_index(choice.id)
    ctx.state = generator.default_state(choice)
    ctx.status_msg = "Loaded " .. choice.name
    apply_live(true)
  end)
end

local function cycle_specimen(delta)
  if not ctx.spec_open then
    ctx.spec_open = true
  else
    ctx.spec_idx = ((ctx.spec_idx - 1 + delta) % #specimens.list) + 1
  end
  ctx.status_msg = "Preview: " .. specimens.list[ctx.spec_idx].label
  render()
end

local function bind_keys(buf)
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end

  map("j", function()
    local dials = get_dials()
    ctx.cursor_row = (ctx.cursor_row % #dials) + 1
    render()
  end)
  map("<Down>", function()
    local dials = get_dials()
    ctx.cursor_row = (ctx.cursor_row % #dials) + 1
    render()
  end)
  map("k", function()
    local dials = get_dials()
    ctx.cursor_row = ((ctx.cursor_row - 2) % #dials) + 1
    render()
  end)
  map("<Up>", function()
    local dials = get_dials()
    ctx.cursor_row = ((ctx.cursor_row - 2) % #dials) + 1
    render()
  end)

  local function adjust(delta, big)
    local dials = get_dials()
    local dial = dials[ctx.cursor_row]
    if dial and dial.step then
      dial.step(delta, big)
      schedule_apply()
    end
  end

  map("h", function()
    adjust(-1, false)
  end)
  map("<Left>", function()
    adjust(-1, false)
  end)
  map("l", function()
    adjust(1, false)
  end)
  map("<Right>", function()
    adjust(1, false)
  end)
  map("H", function()
    adjust(-1, true)
  end)
  map("L", function()
    adjust(1, true)
  end)

  map("[", function()
    ctx.preset_idx = ((ctx.preset_idx - 2) % #ctx.all_presets) + 1
    local p = ctx.all_presets[ctx.preset_idx]
    ctx.state = generator.default_state(p)
    ctx.status_msg = string.format("[%s] %s", p.category or "preset", p.name)
    apply_live(true)
  end)
  map("]", function()
    ctx.preset_idx = (ctx.preset_idx % #ctx.all_presets) + 1
    local p = ctx.all_presets[ctx.preset_idx]
    ctx.state = generator.default_state(p)
    ctx.status_msg = string.format("[%s] %s", p.category or "preset", p.name)
    apply_live(true)
  end)

  -- Specimen preview toggle + language switching
  map("s", function()
    ctx.spec_open = not ctx.spec_open
    ctx.status_msg = ctx.spec_open and ("Preview: " .. specimens.list[ctx.spec_idx].label) or "Preview hidden"
    render()
  end)
  map("<Tab>", function()
    cycle_specimen(1)
  end)
  map("<S-Tab>", function()
    cycle_specimen(-1)
  end)
  for i = 1, #specimens.list do
    map(tostring(i), function()
      ctx.spec_open = true
      ctx.spec_idx = i
      ctx.status_msg = "Preview: " .. specimens.list[i].label
      render()
    end)
  end

  map("p", open_preset_picker)

  map("r", function()
    M.sync_from_rex(false)
  end)

  map("c", function()
    local sampled = ctx.original_sample or presets.from_current_nvim()
    ctx.preset_idx = upsert_preset(sampled)
    ctx.state = generator.default_state(sampled)
    ctx.status_msg = "Sampled " .. sampled.name
    apply_live(true)
  end)

  map("m", function()
    ctx.state.polarity = ctx.state.polarity == "dark" and "light" or "dark"
    ctx.status_msg = "Polarity: " .. ctx.state.polarity
    apply_live(true)
  end)

  map("z", randomize_studio)

  map("0", function()
    local p = ctx.all_presets[ctx.preset_idx]
    if p then
      ctx.state = generator.default_state(p)
      ctx.status_msg = "Reset to " .. p.name
      apply_live(true)
    end
  end)

  map("x", function()
    if ctx.palette then
      rex.push_to_rex(ctx.palette, function(ok, err)
        ctx.status_msg = ok and "Pushed palette to Rex pane" or ("Rex: " .. (err or "failed"))
        render()
      end)
    end
  end)

  map("w", function()
    M.export_current()
  end)

  map("<CR>", function()
    local dials = get_dials()
    local dial = dials[ctx.cursor_row]
    if dial and dial.id == "preset" then
      open_preset_picker()
      return
    end
    ctx.saved_or_kept = true
    close_panel(false)
  end)

  map("q", function()
    close_panel(true)
  end)
  map("<Esc>", function()
    close_panel(true)
  end)
end

local function is_current_buffer_empty()
  local cur_buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(cur_buf)
  local line_count = vim.api.nvim_buf_line_count(cur_buf)
  if name == "" and line_count <= 1 then
    local first = vim.api.nvim_buf_get_lines(cur_buf, 0, 1, false)[1] or ""
    return first == ""
  end
  return false
end

function M.open(opts)
  opts = opts or {}
  if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
    if opts.specimen ~= nil then
      ctx.spec_open = opts.specimen
      render()
    end
    vim.api.nvim_set_current_win(ctx.win)
    return
  end

  if #ctx.all_presets == 0 then
    load_preset_list()
  end

  ctx.original_colorscheme = vim.g.colors_name
  ctx.original_background = vim.o.background
  if vim.g.colors_name ~= "themenav-live" then
    ctx.original_sample = presets.from_current_nvim()
  end
  ctx.saved_or_kept = false
  ctx.status_msg = nil

  -- Auto-open specimen preview if explicitly requested or if user opened studio on a blank buffer
  if opts.specimen ~= nil then
    ctx.spec_open = opts.specimen
  else
    ctx.spec_open = is_current_buffer_empty()
  end

  if opts.preset or not ctx.state then
    local start_id = opts.preset or "merino-dark"
    ctx.preset_idx = find_preset_index(start_id)
    ctx.state = generator.default_state(ctx.all_presets[ctx.preset_idx])
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "themenav"

  local initial = compute_layout(20)
  local win = vim.api.nvim_open_win(
    buf,
    true,
    vim.tbl_extend("force", initial.panel, {
      style = "minimal",
      border = "rounded",
      title = " Theme Studio (OKLCH) ",
      title_pos = "center",
      zindex = 60,
    })
  )

  vim.wo[win].winhl = "Normal:ThemeNavNormal,FloatBorder:ThemeNavBorder,FloatTitle:ThemeNavTitle"
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  vim.wo[win].colorcolumn = ""
  vim.wo[win].list = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  ctx.buf = buf
  ctx.win = win
  bind_keys(buf)

  -- Re-dock & clamp smoothly whenever the terminal or Rex pane zooms/resizes
  ctx.resize_augroup = vim.api.nvim_create_augroup("ThemeNavLayout", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = ctx.resize_augroup,
    callback = function()
      vim.schedule(function()
        if ctx.win and vim.api.nvim_win_is_valid(ctx.win) then
          render()
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = ctx.resize_augroup,
    pattern = tostring(win),
    callback = function()
      vim.schedule(function()
        if ctx.win == win then
          close_panel(true)
        end
      end)
    end,
  })

  apply_live(true)

  rex.read_custom_themes(function(custom)
    for _, p in ipairs(custom) do
      upsert_preset(p)
    end
  end)

  if opts.from_rex then
    M.sync_from_rex(true)
  end
end

function M.list_presets()
  if #ctx.all_presets == 0 then
    load_preset_list()
  end
  local ids = {}
  for _, p in ipairs(ctx.all_presets) do
    ids[#ids + 1] = p.id
  end
  return ids
end

return M
