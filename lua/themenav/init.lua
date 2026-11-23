-- Real-time OKLCH Theme Navigator & Studio for Neovim + Rex (lazy-loaded on first use).
local M = {}

local function ui()
  return require("themenav.ui")
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("ThemeNav", function(cmd)
    local arg = cmd.args and cmd.args:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if arg == "rex" then
      ui().open({ from_rex = true })
    elseif arg == "preview" or arg == "specimen" then
      ui().open({ specimen = true })
    elseif arg ~= "" then
      ui().open({ preset = arg })
    else
      ui().open()
    end
  end, {
    nargs = "?",
    desc = "Open real-time OKLCH Theme Navigator & Studio",
    complete = function(lead)
      local list = { "rex", "preview" }
      for _, id in ipairs(ui().list_presets()) do
        list[#list + 1] = id
      end
      return vim.tbl_filter(function(item)
        return vim.startswith(item, lead)
      end, list)
    end,
  })

  vim.api.nvim_create_user_command("ThemeNavRex", function()
    ui().sync_from_rex(false)
  end, { desc = "Sync active Rex terminal palette into Neovim (OKLCH derived)" })

  vim.api.nvim_create_user_command("ThemeNavPreset", function(cmd)
    local ok, preset = ui().apply_preset_by_id(cmd.args)
    if ok and preset then
      vim.notify("themenav: applied " .. preset.name, vim.log.levels.INFO)
    else
      vim.notify("themenav: unknown preset " .. cmd.args, vim.log.levels.WARN)
    end
  end, {
    nargs = 1,
    desc = "Apply a themenav preset directly",
    complete = function(lead)
      return vim.tbl_filter(function(item)
        return vim.startswith(item, lead)
      end, ui().list_presets())
    end,
  })

  vim.api.nvim_create_user_command("ThemeNavExport", function(cmd)
    ui().export_current(cmd.args)
  end, {
    nargs = "?",
    desc = "Export current generated theme to colors/<name>.lua + Rex/Ghostty .conf",
  })

  vim.api.nvim_create_user_command("ThemeNavImportBase16", function(cmd)
    local path = vim.fn.expand(cmd.args)
    local f = io.open(path, "r")
    if not f then
      vim.notify("themenav: cannot read " .. path, vim.log.levels.ERROR)
      return
    end
    local text = f:read("*a")
    f:close()
    local preset, err = require("themenav.presets").from_base16_yaml(text)
    if not preset then
      vim.notify("themenav: " .. (err or "invalid Base16 YAML"), vim.log.levels.ERROR)
      return
    end
    local u = ui()
    u.register_preset(preset)
    u.open({ preset = preset.id })
  end, {
    nargs = 1,
    complete = "file",
    desc = "Import a Base16 YAML scheme and open it in ThemeNav for OKLCH remastering",
  })

  if opts.keymap ~= false then
    vim.keymap.set("n", opts.keymap or "<leader>ut", function()
      ui().open()
    end, { desc = "Theme Navigator / OKLCH Studio" })
  end
end

function M.open(opts)
  return ui().open(opts)
end

function M.sync_from_rex(silent)
  return ui().sync_from_rex(silent)
end

function M.export_current(slug)
  return ui().export_current(slug)
end

return M
