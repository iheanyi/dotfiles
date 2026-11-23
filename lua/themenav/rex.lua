-- Rex terminal palette reader, live set_theme pusher, and Ghostty/Rex theme exporter.
local oklch = require("themenav.oklch")

local M = {}

function M.is_in_rex()
  return (vim.env.REX_BLOCK ~= nil and vim.env.REX_BLOCK ~= "")
    or (vim.env.REX_SESSION ~= nil and vim.env.REX_SESSION ~= "")
    or vim.env.TERM_PROGRAM == "rex"
end

local function rgb_obj_to_hex(obj)
  if type(obj) ~= "table" then
    return nil
  end
  if obj.red and obj.green and obj.blue then
    return oklch.rgb_to_hex(obj.red, obj.green, obj.blue)
  end
  return nil
end

local function parse_osc_rgb(spec)
  if type(spec) ~= "string" then
    return nil
  end
  local r, g, b = spec:match("rgb:(%x+)/(%x+)/(%x+)")
  if not (r and g and b) then
    return nil
  end
  local function norm(h)
    if #h == 4 then
      return tonumber(h:sub(1, 2), 16)
    elseif #h == 2 then
      return tonumber(h, 16)
    elseif #h == 1 then
      return tonumber(h .. h, 16)
    end
    return tonumber(h:sub(1, 2), 16) or 0
  end
  return string.format("#%02x%02x%02x", norm(r), norm(g), norm(b))
end

--- Build a seed preset from an ANSI 0..15 table + optional bg/fg/cursor.
function M.seed_from_ansi(id, name, ansi, bg, fg, cursor, category)
  local bg_hex = bg or ansi[16] or ansi[0] or "#141312"
  local fg_hex = fg or ansi[15] or ansi[7] or "#e6e1d8"
  local bg_L = oklch.hex_to_oklch(bg_hex)
  local polarity = bg_L > 0.6 and "light" or "dark"

  -- Pick the more legible ANSI shade for dark vs light backgrounds.
  local function pick(normal_idx, bright_idx, fallback)
    local a = ansi[normal_idx]
    local b = ansi[bright_idx]
    if a and b then
      if polarity == "dark" then
        return oklch.apca_abs(b, bg_hex) > oklch.apca_abs(a, bg_hex) and b or a
      else
        return oklch.apca_abs(a, bg_hex) >= oklch.apca_abs(b, bg_hex) and a or b
      end
    end
    return a or b or fallback
  end

  local red = pick(1, 9, "#e06c75")
  local green = pick(2, 10, "#8fc98f")
  local yellow = pick(3, 11, "#e5c07b")
  local blue = pick(4, 12, "#6ea8fe")
  local purple = pick(5, 13, "#c099ff")
  local cyan = pick(6, 14, "#66c2cd")
  local orange = oklch.mix(red, yellow, 0.52)

  return {
    id = id,
    name = name,
    category = category or "rex",
    mode = "seed",
    polarity = polarity,
    seed = {
      bg = bg_hex,
      fg = fg_hex,
      cursor = cursor,
      comment = ansi[8],
      red = red,
      orange = orange,
      yellow = yellow,
      green = green,
      cyan = cyan,
      blue = blue,
      purple = purple,
      ansi = ansi,
    },
  }
end

--- Query live terminal OSC 10 (fg), 11 (bg), 12 (cursor) asynchronously via Neovim's TermResponse.
local function query_osc_colors(timeout_ms, cb)
  if #vim.api.nvim_list_uis() == 0 then
    cb({})
    return
  end

  local found = {}
  local done = false
  local group = vim.api.nvim_create_augroup("ThemeNavOscQuery", { clear = true })
  local timer = vim.uv.new_timer()

  local function finish()
    if done then
      return
    end
    done = true
    pcall(vim.api.nvim_del_augroup_by_id, group)
    if timer then
      pcall(function()
        timer:stop()
        timer:close()
      end)
    end
    cb(found)
  end

  vim.api.nvim_create_autocmd("TermResponse", {
    group = group,
    callback = function(ev)
      local seq = ev.data and ev.data.sequence or ""
      local code, spec = seq:match("\27%](1[012]);(rgb:[%x/]+)")
      if code and spec then
        local hex = parse_osc_rgb(spec)
        if code == "10" then
          found.fg = hex
        elseif code == "11" then
          found.bg = hex
        elseif code == "12" then
          found.cursor = hex
        end
        if found.fg and found.bg and found.cursor then
          vim.schedule(finish)
        end
      end
    end,
  })

  pcall(vim.api.nvim_ui_send, "\27]10;?\27\\\27]11;?\27\\\27]12;?\27\\")
  timer:start(timeout_ms or 140, 0, vim.schedule_wrap(finish))
end

local function read_rex_active_theme_id(cb)
  if vim.fn.has("mac") ~= 1 then
    cb(nil)
    return
  end
  vim.system({ "defaults", "read", "com.superlogical.rex" }, { text = true }, function(res)
    local out = (res and res.stdout) or ""
    local dark_id = out:match('"Workspace%.darkThemeID"%s*=%s*"?([^";\n]+)"?')
    local light_id = out:match('"Workspace%.lightThemeID"%s*=%s*"?([^";\n]+)"?')
    vim.schedule(function()
      cb({ dark = dark_id, light = light_id })
    end)
  end)
end

--- Read the live Rex pane's active palette asynchronously via Rex API + OSC 10/11/12.
function M.read_live_palette(cb)
  local session_id = vim.env.REX_SESSION
  local block_id = vim.env.REX_BLOCK
  local osc_colors = nil
  local api_ansi = nil
  local theme_ids = nil
  local pending = 3

  local function maybe_finish()
    pending = pending - 1
    if pending > 0 then
      return
    end
    local ansi = api_ansi or {}
    local bg = (osc_colors and osc_colors.bg) or ansi[16] or ansi[0]
    local fg = (osc_colors and osc_colors.fg) or ansi[15] or ansi[7]
    local cursor = osc_colors and osc_colors.cursor

    if not bg and not fg and vim.tbl_isempty(ansi) then
      cb(nil, "Could not query live Rex/terminal palette")
      return
    end

    local bg_L = oklch.hex_to_oklch(bg or "#141312")
    local is_light = bg_L > 0.6
    local active_id = theme_ids and (is_light and theme_ids.light or theme_ids.dark) or nil
    local label = active_id and ("Rex Live (" .. active_id .. ")") or "Rex Live Palette"

    cb(M.seed_from_ansi("rex-live", label, ansi, bg, fg, cursor, "rex"))
  end

  query_osc_colors(160, function(res)
    osc_colors = res
    maybe_finish()
  end)

  read_rex_active_theme_id(function(ids)
    theme_ids = ids
    maybe_finish()
  end)

  if session_id and block_id and vim.fn.executable("rex") == 1 then
    local payload = vim.json.encode({
      session_id = session_id,
      block_id = block_id,
      args = {
        format = "vt",
        extra_palette = true,
        max_bytes = 24576,
      },
    })
    vim.system({ "rex", "api", "call", "com.superlogical.terminal.format", payload }, { text = true }, function(res)
      local ansi = {}
      if res and res.code == 0 and res.stdout and res.stdout ~= "" then
        local ok, decoded = pcall(vim.json.decode, res.stdout)
        local content = ok and decoded and decoded.content or ""
        for idx_str, spec in content:gmatch("\27%]4;(%d+);(rgb:[%x/]+)") do
          local idx = tonumber(idx_str)
          if idx and (idx <= 16 or idx == 232 or idx == 255) then
            ansi[idx] = parse_osc_rgb(spec)
          end
        end
      end
      vim.schedule(function()
        api_ansi = ansi
        maybe_finish()
      end)
    end)
  else
    api_ansi = {}
    maybe_finish()
  end
end

--- Read Rex's Workspace.customThemes (macOS defaults) asynchronously into seed presets.
function M.read_custom_themes(cb)
  if vim.fn.has("mac") ~= 1 or vim.fn.executable("python3") ~= 1 then
    cb({})
    return
  end
  local script = [[
import json, plistlib, subprocess, sys
try:
    raw = subprocess.check_output(["defaults", "export", "com.superlogical.rex", "-"], stderr=subprocess.DEVNULL)
    pl = plistlib.loads(raw)
    ct = pl.get("Workspace.customThemes")
    if ct:
        sys.stdout.write(ct.decode("utf-8"))
except Exception:
    pass
]]
  vim.system({ "python3", "-c", script }, { text = true }, function(res)
    local out = {}
    if res and res.code == 0 and res.stdout and res.stdout ~= "" then
      local ok, items = pcall(vim.json.decode, res.stdout)
      if ok and type(items) == "table" then
        for _, item in ipairs(items) do
          local p = item.palette
          if type(p) == "table" then
            local ansi = {}
            if type(p.ansi) == "table" then
              for i, col in ipairs(p.ansi) do
                ansi[i - 1] = rgb_obj_to_hex(col)
              end
            end
            local bg = rgb_obj_to_hex(p.background)
            local fg = rgb_obj_to_hex(p.foreground)
            local cursor = rgb_obj_to_hex(p.cursor)
            local name = item.name or item.id or "Rex Custom"
            local id = "rex-custom-" .. name:lower():gsub("[^%w]+", "-")
            out[#out + 1] = M.seed_from_ansi(id, "Rex: " .. name, ansi, bg, fg, cursor, "rex")
          end
        end
      end
    end
    vim.schedule(function()
      cb(out)
    end)
  end)
end

--- Push a generated Neovim palette straight into the current Rex terminal pane live.
function M.push_to_rex(palette, cb)
  local session_id = vim.env.REX_SESSION
  local block_id = vim.env.REX_BLOCK
  if not (session_id and block_id and vim.fn.executable("rex") == 1) then
    if cb then
      cb(false, "Not running inside a Rex pane (REX_SESSION / REX_BLOCK unset)")
    end
    return
  end

  local entries = {}
  for i = 0, 15 do
    if palette.ansi and palette.ansi[i] then
      entries[#entries + 1] = string.format("%d=%s", i, palette.ansi[i])
    end
  end

  local payload = vim.json.encode({
    session_id = session_id,
    block_id = block_id,
    args = {
      background = palette.bg,
      foreground = palette.fg,
      cursor = palette.cursor or palette.accent,
      scheme = palette.polarity == "light" and "light" or "dark",
      palette = entries,
    },
  })

  vim.system({ "rex", "api", "call", "com.superlogical.terminal.set_theme", payload }, { text = true }, function(res)
    if cb then
      vim.schedule(function()
        if res and res.code == 0 then
          cb(true)
        else
          cb(false, (res and res.stderr) or "rex set_theme failed")
        end
      end)
    end
  end)
end

--- Format a Ghostty / Rex importable `.conf` theme file.
function M.format_ghostty_conf(name, palette)
  local lines = {
    "# " .. name .. " — generated by themenav (OKLCH)",
    "background = " .. palette.bg,
    "foreground = " .. palette.fg,
    "cursor-color = " .. (palette.cursor or palette.accent),
    "cursor-text = " .. palette.bg,
    "selection-background = " .. palette.bg_sel,
    "selection-foreground = " .. palette.fg,
  }
  for i = 0, 15 do
    local col = palette.ansi and palette.ansi[i] or palette.fg
    lines[#lines + 1] = string.format("palette = %d=%s", i, col)
  end
  return table.concat(lines, "\n") .. "\n"
end

return M
