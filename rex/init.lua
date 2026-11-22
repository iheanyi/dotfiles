rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>p", "client.tab.previous")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>shift+5", "pane.split.right")
rex.bind("ctrl+a>shift+'", "pane.split.down")
rex.bind("ctrl+a>h", "pane.focus.left")
rex.bind("ctrl+a>j", "pane.focus.down")
rex.bind("ctrl+a>k", "pane.focus.up")
rex.bind("ctrl+a>l", "pane.focus.right")
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>[", "pane.copy_mode.enter")

local terminal = "com.superlogical.terminal"

local function cwd(block_id)
  local process = assert(rex.block.call(terminal, "process", { block_id = block_id }))
  if process.foreground and process.foreground.cwd then
    return process.foreground.cwd
  end
  for _, ancestor in ipairs(process.ancestors or {}) do
    if ancestor.cwd then
      return ancestor.cwd
    end
  end
  return assert(process.home, "Rex could not determine the pane's working directory")
end

local function pane(label, directory, command)
  return {
    block = {
      flavor = terminal .. ".shell",
      label = label,
      options = { cwd = directory, command = command, interactive = command ~= nil },
    },
  }
end

local function register_project_layout(name, title, key, agent, command)
  rex.action({
    name = name,
    title = title,
    run = function(ctx)
      local directory = cwd(ctx.block_id)
      local window = assert(rex.session.new_window({
        window_label = directory:match("([^/]+)$") or directory,
        layout = rex.layout.horizontal(
          0.6,
          pane("Editor", directory, { "nvim", "." }),
          rex.layout.vertical(0.5, pane("Shell", directory), pane(agent, directory, { command }))
        ),
      }))
      if ctx.origin == "key" or ctx.origin == "palette" then
        rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window.window_id })
      end
      return window
    end,
  })
  rex.bind("ctrl+a>g>" .. key, name)
end

register_project_layout("project_layout", "Open Project Layout with Claude", "c", "Claude", "claude")
register_project_layout("codex_project_layout", "Open Project Layout with Codex", "x", "Codex", "codex")

rex.action({
  name = "claude_pane",
  title = "Open Claude Pane",
  run = function(ctx)
    return assert(rex.session.new_split({
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = pane("Claude", cwd(ctx.block_id), { "claude" }),
    }))
  end,
})

local function references(block_id)
  local output = assert(rex.block.call(terminal, "format", {
    block_id = block_id,
    format = "text",
    trim = true,
    unwrap = true,
    max_bytes = 524288,
  }))
  local content = output.content
  if output.id then
    local chunk = assert(rex.block.call(terminal, "blob_read", {
      block_id = block_id,
      id = output.id,
      offset = math.max(#content, output.total - 262144),
      max_bytes = 983040,
    }))
    if output.total - 262144 > #content then
      content = chunk.data:match("\n(.*)") or ""
    else
      content = content .. chunk.data
    end
  end

  local matches = {}
  for path, line in content:gmatch("([%w_./-]+):([1-9]%d*)") do
    if path:sub(1, 2) ~= "//" and path:find("%a") then
      matches[#matches + 1] = path .. ":" .. line
    end
  end

  local items, seen = {}, {}
  for index = #matches, 1, -1 do
    local reference = matches[index]
    if not seen[reference] then
      items[#items + 1] = { id = reference, title = reference }
      seen[reference] = true
      if #items == 500 then
        break
      end
    end
  end
  return items
end

local function open_in_editor(block_id, path, line)
  local source = assert(rex.session.describe_block({ block_id = block_id })).block
  local view = assert(rex.session.view({}))
  local path_json = assert(rex.json.encode(path)):gsub("'", "''")
  local expression = "execute('edit +" .. line .. " ' . fnameescape(json_decode('" .. path_json .. "')))"
  for _, window in ipairs(view.windows) do
    if window.window_id == source.window_id then
      for _, layer in ipairs(window.layers) do
        for _, block in ipairs(layer.blocks) do
          if block.creator_name == terminal then
            local process = rex.block.call(terminal, "process", { block_id = block.block_id })
            local foreground = process and process.foreground
            local pane_id = block.block_id:match("^block:([%x-]+)$")
            if foreground and foreground.name == "nvim" and process.home and pane_id then
              local socket = process.home .. "/.cache/rex-nvim/" .. pane_id
              local available = rex.exec({ "test", "-S", socket })
              if available and available.ok then
                local result = assert(
                  rex.exec({ foreground.path, "--server", socket, "--remote-expr", expression }, { timeout = 2 })
                )
                if not result.ok then
                  error(result.stderr ~= "" and result.stderr or "Neovim did not open the reference", 0)
                end
                return assert(rex.session.focus_block({ block_id = block.block_id }))
              end
            end
          end
        end
      end
    end
  end
end

rex.action({
  name = "open_file_reference",
  title = "Open File Reference from Scrollback…",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local items = references(ctx.block_id)
    if #items == 0 then
      error("No file:line references found in this pane", 0)
    end
    local selection = rex.ui.pick({ title = "Open File in Neovim", items = items })
    if not selection then
      return
    end
    local path, line = selection:match("^(.*):(%d+)$")
    if path:sub(1, 1) ~= "/" then
      path = directory .. "/" .. path
    end
    local file = rex.exec({ "test", "-f", path })
    if not (file and file.ok) then
      error("File does not exist from the pane's working directory: " .. path, 0)
    end
    return open_in_editor(ctx.block_id, path, line)
      or assert(rex.session.new_split({
        anchor_id = ctx.block_id,
        direction = "horizontal",
        side = "after",
        focus = true,
        layout = pane("Editor", directory, { "nvim", "+" .. line, "--", path }),
      }))
  end,
})
rex.bind("ctrl+a>f", "open_file_reference")
