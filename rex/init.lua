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

local function pane_info(block_id)
  local process = assert(rex.block.call(terminal, "process", { block_id = block_id }))
  local directory
  if process.foreground and process.foreground.cwd then
    directory = process.foreground.cwd
  else
    for _, ancestor in ipairs(process.ancestors or {}) do
      if ancestor.cwd then
        directory = ancestor.cwd
        break
      end
    end
  end
  directory = directory or assert(process.home, "Rex could not determine the pane's working directory")
  return directory, process.home
end

local function cwd(block_id)
  local directory = pane_info(block_id)
  return directory
end

local function pane(label, directory, command, extra)
  local options = { cwd = directory, command = command, interactive = command ~= nil }
  if extra then
    for key, value in pairs(extra) do
      options[key] = value
    end
  end
  return {
    block = {
      flavor = terminal .. ".shell",
      label = label,
      options = options,
    },
  }
end

local function project_window_layout(directory, agent, command)
  return rex.layout.horizontal(
    0.6,
    pane("Editor", directory, { "nvim", "." }),
    rex.layout.vertical(0.5, pane("Shell", directory), pane(agent, directory, { command }))
  )
end

local function register_project_layout(name, title, key, agent, command)
  rex.action({
    name = name,
    title = title,
    run = function(ctx)
      local directory = cwd(ctx.block_id)
      local window = assert(rex.session.new_window({
        window_label = directory:match("([^/]+)$") or directory,
        layout = project_window_layout(directory, agent, command),
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
register_project_layout("agy_project_layout", "Open Project Layout with Antigravity", "a", "Antigravity", "agy")

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

rex.action({
  name = "agy_pane",
  title = "Open Antigravity Pane",
  run = function(ctx)
    return assert(rex.session.new_split({
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = pane("Antigravity", cwd(ctx.block_id), { "agy" }),
    }))
  end,
})

local function read_scrollback(block_id, format)
  local output = assert(rex.block.call(terminal, "format", {
    block_id = block_id,
    format = format,
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
  return content
end

local function url_decode(value)
  return (value:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

local function parse_file_uri(uri)
  local rest = uri:match("^file://localhost(/.*)$") or uri:match("^file://(/.*)$")
  if not rest then
    return nil
  end
  local path, fragment = rest:match("^([^#]+)#(.*)$")
  path = path or rest
  local line
  if fragment then
    line = fragment:match("^L?([1-9]%d*)")
  end
  if not line then
    local stripped, suffix = path:match("^(.*):([1-9]%d*):?%d*$")
    if stripped then
      path, line = stripped, suffix
    end
  end
  return url_decode(path), line
end

local function resolve_paths(raw_path, directory, home)
  if raw_path == "" or raw_path:sub(1, 2) == "//" then
    return {}
  end
  if raw_path:sub(1, 2) == "~/" then
    if home then
      return { home .. raw_path:sub(2) }
    end
    return {}
  end
  if raw_path:sub(1, 1) == "/" then
    return { raw_path }
  end
  local cleaned = raw_path:gsub("^%./", "")
  if cleaned == "" then
    return {}
  end
  local paths = { directory .. "/" .. cleaned }
  if cleaned:sub(1, 2) == "a/" or cleaned:sub(1, 2) == "b/" then
    paths[#paths + 1] = directory .. "/" .. cleaned:sub(3)
  end
  return paths
end

local function existing_files(paths)
  local existing = {}
  local chunk_size = 200
  for start_index = 1, #paths, chunk_size do
    local argv = {
      "/bin/sh",
      "-c",
      'for p in "$@"; do if [ -f "$p" ]; then printf "%s\\n" "$p"; fi; done',
      "sh",
    }
    local end_index = math.min(start_index + chunk_size - 1, #paths)
    for index = start_index, end_index do
      argv[#argv + 1] = paths[index]
    end
    local result = rex.exec(argv, { timeout = 2 })
    if result and result.ok and result.stdout ~= "" then
      for line in result.stdout:gmatch("[^\n]+") do
        existing[line] = true
      end
    end
  end
  return existing
end

local function format_display(path, directory, home)
  local display = path
  if directory and path:sub(1, #directory + 1) == directory .. "/" then
    display = path:sub(#directory + 2)
  elseif home and path:sub(1, #home + 1) == home .. "/" then
    display = "~" .. path:sub(#home + 1)
  end
  local basename = display:match("([^/]+)$") or display
  local parent = display:match("^(.+)/[^/]+$")
  return basename, parent
end

local function references(block_id, directory, home)
  local text = read_scrollback(block_id, "text")
  local vt = read_scrollback(block_id, "vt")

  local candidates = {}
  local unique_paths, seen_paths = {}, {}

  local function add_candidate(raw_path, line)
    if not raw_path or not raw_path:find("%a") then
      return
    end
    if raw_path:match("^https?://") then
      return
    end
    for _, resolved in ipairs(resolve_paths(raw_path, directory, home)) do
      if not resolved:find("[\r\n]") then
        candidates[#candidates + 1] = { path = resolved, line = line }
        if not seen_paths[resolved] then
          seen_paths[resolved] = true
          unique_paths[#unique_paths + 1] = resolved
        end
      end
    end
  end

  for token in text:gmatch("%S+") do
    local uri = token:match("(file://[^%s%)%]}>\"'`]+)")
    if uri then
      uri = uri:gsub("[.,;:]+$", "")
      local path, line = parse_file_uri(uri)
      if path then
        add_candidate(path, line)
      end
    else
      local cleaned = token:gsub("^[%(%[%'\"<`%{%*]+", ""):gsub("[.,;:!?%)%]'\">`%}%*]+$", "")
      if cleaned ~= "" then
        local path, line = cleaned:match("^(.+):([1-9]%d*):%d+$")
        if not path then
          path, line = cleaned:match("^(.+):([1-9]%d*)%-%d+$")
        end
        if not path then
          path, line = cleaned:match("^(.+):([1-9]%d*)$")
        end
        if not path then
          path, line = cleaned:match("^(.+)#L([1-9]%d*)")
        end
        if not path then
          path = cleaned
        end
        if path:find("/") or path:find("%.%a") then
          add_candidate(path, line)
        end
      end
    end
  end

  -- OSC 8 file:// hyperlinks (e.g., Antigravity / agent links) added last so they rank first.
  for uri in vt:gmatch("\27%]8;[^;\27\7]*;(file://[^\27\7]+)") do
    local path, line = parse_file_uri(uri)
    if path then
      add_candidate(path, line)
    end
  end

  local valid = existing_files(unique_paths)
  local items, by_id, seen = {}, {}, {}
  for index = #candidates, 1, -1 do
    local candidate = candidates[index]
    if valid[candidate.path] then
      local id = candidate.line and (candidate.path .. ":" .. candidate.line) or candidate.path
      if not seen[id] then
        local basename, parent = format_display(candidate.path, directory, home)
        local title = candidate.line and (basename .. ":" .. candidate.line) or basename
        items[#items + 1] = {
          id = id,
          title = title,
          subtitle = parent,
          icon = "document",
        }
        by_id[id] = candidate
        seen[id] = true
        if #items == 500 then
          break
        end
      end
    end
  end
  return items, by_id
end

local function open_in_editor(block_id, path, line, session_id)
  local source = assert(rex.session.describe_block({ session_id = session_id, block_id = block_id })).block
  local view = assert(rex.session.view({ session_id = session_id }))
  local path_json = assert(rex.json.encode(path)):gsub("'", "''")
  local edit_cmd = line and ("edit +" .. line .. " ") or "edit "
  local expression = "execute('" .. edit_cmd .. "' . fnameescape(json_decode('" .. path_json .. "')))"
  for _, window in ipairs(view.windows) do
    if window.window_id == source.window_id then
      for _, layer in ipairs(window.layers) do
        for _, block in ipairs(layer.blocks) do
          if block.creator_name == terminal then
            local process = rex.block.call(terminal, "process", { session_id = session_id, block_id = block.block_id })
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
                return assert(rex.session.focus_block({ session_id = session_id, block_id = block.block_id }))
              end
            end
          end
        end
      end
    end
  end
end

local function session_view(session_id)
  local view = rex.session.view({ session_id = session_id })
  if view then
    return view
  end
  local attached = rex.call("session.attach", { session_id = session_id })
  return (attached and attached.view) or rex.session.view({ session_id = session_id })
end

local function find_target_for_file(path)
  local listed = assert(rex.call("session.list", {}))
  local best_cwd_match, best_cwd_len = nil, -1
  local scrollback_match = nil
  local fallback = nil

  for _, session in ipairs(listed.sessions or {}) do
    local view = session_view(session.session_id)
    if view and view.windows and #view.windows > 0 then
      local active_window
      for _, window in ipairs(view.windows) do
        if window.window_id == view.active_window_id then
          active_window = window
          break
        end
      end
      active_window = active_window or view.windows[1]

      local anchor_block_id = active_window.focused_block_id
      local window_dir
      for _, layer in ipairs(active_window.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.creator_name == terminal then
            anchor_block_id = anchor_block_id or block.block_id
            local process = rex.block.call(terminal, "process", {
              session_id = session.session_id,
              block_id = block.block_id,
            })
            local dir = process and process.foreground and process.foreground.cwd
            if not dir and process then
              for _, ancestor in ipairs(process.ancestors or {}) do
                if ancestor.cwd then
                  dir = ancestor.cwd
                  break
                end
              end
            end
            if dir then
              window_dir = window_dir or dir
              local home = process and process.home
              if
                dir ~= "/"
                and dir ~= home
                and (path == dir or path:sub(1, #dir + 1) == dir .. "/")
                and #dir > best_cwd_len
              then
                best_cwd_len = #dir
                best_cwd_match = {
                  session_id = session.session_id,
                  window_id = active_window.window_id,
                  block_id = anchor_block_id,
                  directory = dir,
                }
              end
            end
            if not scrollback_match then
              local out = rex.block.call(terminal, "format", {
                session_id = session.session_id,
                block_id = block.block_id,
                format = "vt",
                trim = true,
                unwrap = true,
                max_bytes = 262144,
              })
              if out and out.content and out.content:find(path, 1, true) then
                scrollback_match = {
                  session_id = session.session_id,
                  window_id = active_window.window_id,
                  block_id = block.block_id,
                  directory = dir or window_dir,
                }
              end
            end
          end
        end
      end

      if not fallback and anchor_block_id then
        fallback = {
          session_id = session.session_id,
          window_id = active_window.window_id,
          block_id = anchor_block_id,
          directory = window_dir,
        }
      end
    end
  end

  return best_cwd_match or scrollback_match or fallback
end

local function is_markdown_path(path)
  local lower = path:lower()
  return lower:match("%.md$") ~= nil
    or lower:match("%.mdx$") ~= nil
    or lower:match("%.markdown$") ~= nil
    or lower:match("%.mkd$") ~= nil
end

local function open_floating(block_id, label, directory, command, bounds, extra, session_id)
  local source = assert(rex.session.describe_block({ session_id = session_id, block_id = block_id })).block
  return assert(rex.session.new_layer({
    session_id = session_id,
    window_id = source.window_id,
    bounds = bounds or { 0.04, 0.05, 0.92, 0.90 },
    focus = true,
    layout = pane(label, directory, command, extra),
  }))
end

local function resolve_explicit_target(session_id, block_id)
  if not (session_id and block_id) then
    return nil
  end
  local described = rex.session.describe_block({ session_id = session_id, block_id = block_id })
  if not (described and described.block) then
    return nil
  end
  local process = rex.block.call(terminal, "process", { session_id = session_id, block_id = block_id })
  local dir = process and process.foreground and process.foreground.cwd
  if not dir and process then
    for _, ancestor in ipairs(process.ancestors or {}) do
      if ancestor.cwd then
        dir = ancestor.cwd
        break
      end
    end
  end
  return {
    session_id = session_id,
    window_id = described.block.window_id,
    block_id = block_id,
    directory = dir,
  }
end

rex.action({
  name = "open_file",
  title = "Open File in Rex",
  args = {
    path = "string",
    line = "string?",
    mode = "string?",
    session_id = "string?",
    block_id = "string?",
  },
  run = function(ctx, args)
    local path = args.path
    local line = args.line
    local mode = args.mode or "split"
    local basename = path:match("([^/]+)$") or "Editor"
    local file_dir = path:match("^(.+)/[^/]+$") or "/"

    if mode == "pick" then
      local choices = {
        { id = "split", title = "Open in Neovim Split", subtitle = basename, icon = "code" },
        { id = "float", title = "Open in Floating Neovim", subtitle = basename, icon = "document" },
        { id = "tab", title = "Open in New Tab", subtitle = basename, icon = "terminal" },
      }
      if is_markdown_path(path) then
        choices[#choices + 1] = {
          id = "glow",
          title = "Preview in Glow (Markdown)",
          subtitle = basename,
          icon = "document",
        }
      end
      choices[#choices + 1] = {
        id = "tuicr",
        title = "Annotate in tuicr",
        subtitle = basename,
        icon = "branch",
      }
      mode = rex.ui.pick({
        title = "Open " .. basename,
        placeholder = "Choose how to open this file in Rex",
        items = choices,
      })
      if not mode then
        return
      end
    end

    local target = resolve_explicit_target(args.session_id, args.block_id)
      or resolve_explicit_target(ctx.session_id, ctx.block_id)
      or find_target_for_file(path)

    local nvim_cmd = line and { "nvim", "+" .. line, "--", path } or { "nvim", "--", path }
    local tuicr_cmd = line and { "tuicr", "--file", path, "--line", line } or { "tuicr", "--file", path }
    local glow_cmd = { "glow", "-t", path }

    if target then
      local work_dir = target.directory or file_dir
      local selected_window_id = target.window_id
      local result

      if mode == "float" then
        result = open_floating(target.block_id, basename, work_dir, nvim_cmd, nil, nil, target.session_id)
      elseif mode == "glow" then
        result = open_floating(target.block_id, basename, work_dir, glow_cmd, nil, nil, target.session_id)
      elseif mode == "tuicr" then
        result = open_floating(target.block_id, "Review " .. basename, work_dir, tuicr_cmd, nil, nil, target.session_id)
      elseif mode == "tab" or mode == "window" then
        result = assert(rex.session.new_window({
          session_id = target.session_id,
          window_label = basename,
          layout = pane("Editor", work_dir, nvim_cmd),
        }))
        selected_window_id = result.window_id
      else
        result = open_in_editor(target.block_id, path, line, target.session_id)
          or assert(rex.session.new_split({
            session_id = target.session_id,
            anchor_id = target.block_id,
            direction = "horizontal",
            side = "after",
            focus = true,
            layout = pane("Editor", work_dir, nvim_cmd),
          }))
      end

      rex.client.queue("session.select", { session_id = target.session_id, window_id = selected_window_id })
      return result
    end

    local cmd = mode == "glow" and glow_cmd or (mode == "tuicr" and tuicr_cmd or nvim_cmd)
    local created = assert(rex.call("session.create", {
      label = "editor",
      initial_windows = {
        {
          window_label = basename,
          layout = pane("Editor", file_dir, cmd),
        },
      },
    }))
    local window_id = created.initial_windows and created.initial_windows[1] and created.initial_windows[1].window_id
    rex.client.queue("session.select", { session_id = created.session_id, window_id = window_id })
    return created
  end,
})

rex.action({
  name = "open_file_reference",
  title = "Open File Reference from Scrollback…",
  run = function(ctx)
    local directory, home = pane_info(ctx.block_id)
    local items, by_id = references(ctx.block_id, directory, home)
    if #items == 0 then
      error("No file references found in this pane", 0)
    end
    local selection = rex.ui.pick({ title = "Open File in Neovim", items = items })
    if not selection then
      return
    end
    local chosen = by_id[selection]
    if not chosen then
      return
    end
    local nvim_cmd = chosen.line and { "nvim", "+" .. chosen.line, "--", chosen.path } or { "nvim", "--", chosen.path }
    return open_in_editor(ctx.block_id, chosen.path, chosen.line)
      or assert(rex.session.new_split({
        anchor_id = ctx.block_id,
        direction = "horizontal",
        side = "after",
        focus = true,
        layout = pane("Editor", directory, nvim_cmd),
      }))
  end,
})
rex.bind("ctrl+a>f", "open_file_reference")

rex.action({
  name = "preview_markdown",
  title = "Preview Markdown in Glow…",
  run = function(ctx)
    local directory, home = pane_info(ctx.block_id)
    local items, by_id = references(ctx.block_id, directory, home)
    local md_items, seen_paths = {}, {}
    for _, item in ipairs(items) do
      local candidate = by_id[item.id]
      if candidate and is_markdown_path(candidate.path) and not seen_paths[candidate.path] then
        seen_paths[candidate.path] = true
        local basename, parent = format_display(candidate.path, directory, home)
        md_items[#md_items + 1] = {
          id = candidate.path,
          title = basename,
          subtitle = parent,
          icon = "document",
        }
      end
    end

    local target
    if #md_items == 0 then
      target = directory
    else
      local dir_name = directory:match("([^/]+)$") or directory
      md_items[#md_items + 1] = {
        id = "__browse__",
        title = "Browse Markdown in " .. dir_name,
        subtitle = directory,
        icon = "folder",
      }
      local selection = rex.ui.pick({
        title = "Preview Markdown in Glow",
        placeholder = "Filter Markdown files or enter a path",
        items = md_items,
        allow_other = true,
      })
      if not selection then
        return
      end
      if type(selection) == "table" then
        local typed = selection.text:gsub("^%s+", ""):gsub("%s+$", "")
        if typed == "" then
          return
        end
        local resolved = resolve_paths(typed, directory, home)[1]
        if not resolved then
          error("Invalid Markdown path: " .. typed, 0)
        end
        target = resolved
      elseif selection == "__browse__" then
        target = directory
      else
        target = selection
      end
    end

    local label = target == directory and "Markdown" or (target:match("([^/]+)$") or "Markdown")
    return assert(rex.session.new_split({
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = pane(label, directory, { "glow", "-t", target }),
    }))
  end,
})
rex.bind("ctrl+a>m", "preview_markdown")

local function git_stdout(directory, ...)
  local argv = { "git", "-C", directory, ... }
  local result = rex.exec(argv, { timeout = 2 })
  if result and result.ok then
    return (result.stdout:gsub("%s+$", ""))
  end
  return nil
end

local function git_info(directory)
  local root = git_stdout(directory, "rev-parse", "--show-toplevel")
  if not root or root == "" then
    return nil
  end
  local status = git_stdout(root, "status", "--porcelain") or ""
  local dirty = 0
  for _ in status:gmatch("[^\n]+") do
    dirty = dirty + 1
  end
  local branch = git_stdout(root, "rev-parse", "--abbrev-ref", "HEAD") or "HEAD"
  local base = git_stdout(root, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
  if base then
    base = base:gsub("^origin/", "")
  elseif git_stdout(root, "show-ref", "--verify", "--quiet", "refs/heads/main") then
    base = "main"
  elseif git_stdout(root, "show-ref", "--verify", "--quiet", "refs/heads/master") then
    base = "master"
  end
  local ahead = 0
  if base and branch ~= base and branch ~= "HEAD" then
    ahead = tonumber(git_stdout(root, "rev-list", "--count", base .. "..HEAD")) or 0
  end
  return {
    root = root,
    branch = branch,
    base = base,
    dirty = dirty,
    ahead = ahead,
  }
end

local exec_path = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
local function exec_with_path(argv, opts)
  local merged = { timeout = 2, env = { PATH = exec_path } }
  if opts then
    for key, value in pairs(opts) do
      if key == "env" then
        for ek, ev in pairs(value) do
          merged.env[ek] = ev
        end
      else
        merged[key] = value
      end
    end
  end
  return rex.exec(argv, merged)
end

local function fetch_repo_prs(repo_root)
  local script = [[
import concurrent.futures, json, subprocess, sys

cwd = sys.argv[1]
fields = "number,title,author,headRefName,isDraft,reviewDecision,additions,deletions,url"

def run(extra):
    cmd = ["gh", "pr", "list", "--state", "open", "--json", fields] + extra
    proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if proc.returncode != 0:
        return None, (proc.stderr or proc.stdout or "gh pr list failed").strip()
    try:
        return json.loads(proc.stdout or "[]"), None
    except Exception as exc:
        return None, str(exc)

with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    f_req = pool.submit(run, ["--search", "review-requested:@me", "--limit", "30"])
    f_open = pool.submit(run, ["--limit", "50"])
    req, req_err = f_req.result()
    open_prs, open_err = f_open.result()

out = {
    "requested": req or [],
    "open": open_prs or [],
    "error": open_err if open_prs is None else (req_err if req is None and not open_prs else None),
}
sys.stdout.write(json.dumps(out))
]]
  local result = exec_with_path({ "python3", "-c", script, repo_root }, { timeout = 10 })
  if not (result and result.ok and result.stdout and result.stdout ~= "") then
    return nil, (result and result.stderr ~= "" and result.stderr) or "Failed to query GitHub PRs via gh"
  end
  local ok, decoded = pcall(rex.json.decode, result.stdout)
  if not (ok and type(decoded) == "table") then
    return nil, "Could not parse gh pr list output"
  end
  if decoded.error and #decoded.open == 0 and #decoded.requested == 0 then
    return nil, decoded.error
  end
  return decoded, nil
end

local function review_pr_picker(ctx, directory, info)
  local work_dir = (info and info.root) or directory
  local items, by_id, seen = {}, {}, {}

  if info then
    local data, err = fetch_repo_prs(info.root)
    if not data then
      error(err or "Could not fetch pull requests", 0)
    end

    local function append_prs(list, is_requested)
      for _, pr in ipairs(list or {}) do
        local num = pr.number
        if num and not seen[num] then
          seen[num] = true
          local id = tostring(num)
          local author = (type(pr.author) == "table" and pr.author.login) or "unknown"
          local branch = pr.headRefName or ""
          local stats = ""
          if pr.additions ~= nil and pr.deletions ~= nil then
            stats = string.format("+%d/-%d", pr.additions, pr.deletions)
          end
          local sub_parts = { "@" .. author }
          if branch ~= "" then
            sub_parts[#sub_parts + 1] = branch
          end
          if stats ~= "" then
            sub_parts[#sub_parts + 1] = stats
          end

          local detail = "open"
          if is_requested then
            detail = pr.isDraft and "draft · review req" or "review requested"
          elseif pr.isDraft then
            detail = "draft"
          elseif pr.reviewDecision == "CHANGES_REQUESTED" then
            detail = "changes requested"
          elseif pr.reviewDecision == "APPROVED" then
            detail = "approved"
          end

          items[#items + 1] = {
            id = id,
            title = "#" .. id .. " " .. (pr.title or ""),
            subtitle = table.concat(sub_parts, " · "),
            detail = detail,
            icon = "branch",
          }
          by_id[id] = pr
        end
      end
    end

    append_prs(data.requested, true)
    append_prs(data.open, false)
  end

  local selection
  if #items == 0 then
    local typed = rex.ui.input({
      title = "Review Pull Request in tuicr",
      placeholder = "No open PRs found — enter PR #, owner/repo#N, or PR URL",
      confirm = "Open in tuicr",
    })
    if not typed then
      return
    end
    selection = { text = typed }
  else
    selection = rex.ui.pick({
      title = "Review Pull Request in tuicr",
      placeholder = "Filter PRs by #number, title, @author, branch, or enter a PR URL",
      items = items,
      allow_other = true,
    })
    if not selection then
      return
    end
  end

  local target, label
  if type(selection) == "table" then
    local typed = selection.text:gsub("^%s+", ""):gsub("%s+$", "")
    if typed == "" then
      return
    end
    target = typed:gsub("^#(%d+)$", "%1")
    label = target:match("^%d+$") and ("Review PR #" .. target) or ("Review " .. target)
  else
    target = selection
    label = "Review PR #" .. selection
  end

  return open_floating(ctx.block_id, label, work_dir, { "tuicr", "pr", target })
end

rex.action({
  name = "review_pr_with_tuicr",
  title = "Review Pull Request in tuicr…",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    return review_pr_picker(ctx, directory, info)
  end,
})
rex.bind("ctrl+a>shift+p", "review_pr_with_tuicr")

rex.action({
  name = "review_with_tuicr",
  title = "Review with tuicr…",
  run = function(ctx)
    local directory, home = pane_info(ctx.block_id)
    local info = git_info(directory)
    local work_dir = (info and info.root) or directory

    local items = {}
    if info then
      items[#items + 1] = {
        id = "working_tree",
        title = "Working tree changes",
        subtitle = info.branch,
        icon = "branch",
        detail = info.dirty > 0 and (info.dirty .. " changed") or "clean",
      }
      if info.base and info.ahead > 0 then
        local detail = info.ahead .. (info.ahead == 1 and " commit" or " commits")
        if info.dirty > 0 then
          detail = detail .. " + " .. info.dirty .. " dirty"
        end
        items[#items + 1] = {
          id = "branch_diff",
          title = "Branch diff (" .. info.base .. ".." .. info.branch .. ")",
          subtitle = info.dirty > 0 and "Branch commits + uncommitted changes" or "Committed branch changes",
          icon = "code",
          detail = detail,
        }
      end
      items[#items + 1] = {
        id = "pull_requests",
        title = "Pull requests…",
        subtitle = "List open & review-requested PRs in this repo",
        icon = "branch",
      }
      items[#items + 1] = {
        id = "commits",
        title = "Choose commits…",
        subtitle = "Open tuicr commit selector",
        icon = "clock",
      }
    end

    local refs, by_id = references(ctx.block_id, directory, home)
    local md_files, other_files, seen_paths = {}, {}, {}
    for _, ref in ipairs(refs) do
      local candidate = by_id[ref.id]
      if candidate and not seen_paths[candidate.path] then
        seen_paths[candidate.path] = true
        if is_markdown_path(candidate.path) then
          md_files[#md_files + 1] = candidate.path
        elseif #other_files < 10 then
          other_files[#other_files + 1] = candidate.path
        end
      end
    end

    local function append_file_items(paths, detail)
      for _, path in ipairs(paths) do
        local basename, parent = format_display(path, directory, home)
        items[#items + 1] = {
          id = "file:" .. path,
          title = "Annotate " .. basename,
          subtitle = parent,
          icon = "document",
          detail = detail,
        }
      end
    end
    append_file_items(md_files, "markdown")
    append_file_items(other_files, "file")

    if #items == 0 then
      error("Not in a git repository and no files found in this pane to annotate", 0)
    end

    local selection = rex.ui.pick({
      title = "Review with tuicr",
      placeholder = "Pick a review target, or enter a revset / file path",
      items = items,
      allow_other = true,
    })
    if not selection then
      return
    end

    local cmd, label
    if type(selection) == "table" then
      local typed = selection.text:gsub("^%s+", ""):gsub("%s+$", "")
      if typed == "" then
        return
      end
      local resolved = resolve_paths(typed, directory, home)[1]
      local is_file = resolved and existing_files({ resolved })[resolved]
      if is_file then
        cmd = { "tuicr", "--file", resolved }
        label = "Review " .. (resolved:match("([^/]+)$") or "File")
      else
        cmd = { "tuicr", "-r", typed }
        label = "Review " .. typed
      end
    elseif selection == "working_tree" then
      cmd = { "tuicr", "-w" }
      label = "Review Diff"
    elseif selection == "branch_diff" then
      cmd = info.dirty > 0 and { "tuicr", "-r", info.base .. "..HEAD", "-w" }
        or { "tuicr", "-r", info.base .. "..HEAD" }
      label = "Review " .. info.branch
    elseif selection == "pull_requests" then
      return review_pr_picker(ctx, directory, info)
    elseif selection == "commits" then
      cmd = { "tuicr" }
      label = "Review Commits"
    elseif selection:sub(1, 5) == "file:" then
      local path = selection:sub(6)
      cmd = { "tuicr", "--file", path }
      label = "Review " .. (path:match("([^/]+)$") or "File")
    else
      return
    end

    return open_floating(ctx.block_id, label, work_dir, cmd)
  end,
})
rex.bind("ctrl+a>r", "review_with_tuicr")

rex.action({
  name = "review_working_tree",
  title = "Review Working Tree in tuicr",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    if not info then
      error("Current pane is not in a git repository: " .. directory, 0)
    end
    return open_floating(ctx.block_id, "Review Diff", info.root, { "tuicr", "-w" })
  end,
})
rex.bind("ctrl+a>shift+r", "review_working_tree")

local agent_names = {
  agy = "Antigravity",
  claude = "Claude",
  codex = "Codex",
  opencode = "OpenCode",
}

local status_priority = {
  blocked = 1,
  error = 2,
  done = 3,
  working = 4,
  idle = 5,
}

local function list_agent_panes(current_session_id, exclude_block_id)
  local listed = assert(rex.call("session.list", {}))
  local entries = {}
  for _, session in ipairs(listed.sessions or {}) do
    local view = session_view(session.session_id)
    if view then
      for _, window in ipairs(view.windows or {}) do
        for _, layer in ipairs(window.layers or {}) do
          for _, block in ipairs(layer.blocks or {}) do
            if block.creator_name == terminal and block.block_id ~= exclude_block_id then
              local process = rex.block.call(terminal, "process", {
                session_id = session.session_id,
                block_id = block.block_id,
              })
              local status = rex.block.call(terminal, "program_status", {
                session_id = session.session_id,
                block_id = block.block_id,
              })
              local fg = process and process.foreground
              local fg_name = fg and fg.name
              local records = (status and status.records) or {}
              local best_record, best_rank = nil, 99
              for _, record in ipairs(records) do
                local rank = status_priority[record.state] or 5
                if rank < best_rank then
                  best_rank = rank
                  best_record = record
                end
              end
              if (fg_name and agent_names[fg_name]) or best_record then
                local app_label = (fg_name and agent_names[fg_name])
                  or (best_record and (best_record.effective_app or best_record.app))
                  or fg_name
                  or block.label
                  or "Agent"
                local dir = fg and fg.cwd
                if not dir and process then
                  for _, ancestor in ipairs(process.ancestors or {}) do
                    if ancestor.cwd then
                      dir = ancestor.cwd
                      break
                    end
                  end
                end
                local dir_name = dir and (dir:match("([^/]+)$") or dir) or nil
                local state = best_record and best_record.state or "running"
                local note = best_record and (best_record.msg or best_record.title)
                local subtitle_parts = { session.label }
                if dir_name and dir_name ~= session.label then
                  subtitle_parts[#subtitle_parts + 1] = dir_name
                end
                if note and note ~= "" then
                  subtitle_parts[#subtitle_parts + 1] = note
                end
                entries[#entries + 1] = {
                  session_id = session.session_id,
                  session_label = session.label,
                  window_id = window.window_id,
                  block_id = block.block_id,
                  app_label = app_label,
                  state = state,
                  priority = best_rank,
                  same_session = session.session_id == current_session_id,
                  subtitle = table.concat(subtitle_parts, " · "),
                }
              end
            end
          end
        end
      end
    end
  end
  return entries
end

rex.action({
  name = "jump_to_agent",
  title = "Jump to Agent Pane…",
  run = function(ctx)
    local entries = list_agent_panes(ctx.session_id, nil)
    if #entries == 0 then
      error("No running agent panes found across Rex sessions", 0)
    end
    table.sort(entries, function(a, b)
      if a.priority ~= b.priority then
        return a.priority < b.priority
      end
      if a.same_session ~= b.same_session then
        return a.same_session
      end
      return a.session_label < b.session_label
    end)
    local items, by_id = {}, {}
    for _, entry in ipairs(entries) do
      items[#items + 1] = {
        id = entry.block_id,
        title = entry.app_label,
        subtitle = entry.subtitle,
        detail = entry.state,
        icon = "terminal",
      }
      by_id[entry.block_id] = entry
    end
    local selection = rex.ui.pick({
      title = "Jump to Agent Pane",
      placeholder = "Filter by agent, session, or status",
      items = items,
    })
    if not selection then
      return
    end
    local target = by_id[selection]
    if not target then
      return
    end
    rex.session.focus_block({ session_id = target.session_id, block_id = target.block_id })
    rex.client.queue("session.select", { session_id = target.session_id, window_id = target.window_id })
    return target
  end,
})
rex.bind("ctrl+a>a", "jump_to_agent")

rex.action({
  name = "send_scrollback_to_agent",
  title = "Send Scrollback to Agent…",
  run = function(ctx)
    local entries = list_agent_panes(ctx.session_id, ctx.block_id)
    if #entries == 0 then
      error("No other agent panes found to send scrollback to", 0)
    end
    table.sort(entries, function(a, b)
      if a.same_session ~= b.same_session then
        return a.same_session
      end
      return a.priority < b.priority
    end)
    local items, by_id = {}, {}
    for _, entry in ipairs(entries) do
      items[#items + 1] = {
        id = entry.block_id,
        title = entry.app_label,
        subtitle = entry.subtitle,
        detail = entry.state,
        icon = "terminal",
      }
      by_id[entry.block_id] = entry
    end
    local selection = rex.ui.pick({
      title = "Send Scrollback to Agent",
      placeholder = "Choose target agent pane",
      items = items,
    })
    if not selection then
      return
    end
    local target = by_id[selection]
    if not target then
      return
    end

    local note = rex.ui.input({
      title = "Note for " .. target.app_label,
      placeholder = "Optional instruction prefix (leave empty to paste raw output)",
      confirm = "Paste into " .. target.app_label,
    })
    if note == nil then
      return
    end

    local raw = read_scrollback(ctx.block_id, "text")
    local lines = {}
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
      lines[#lines + 1] = line
    end
    while #lines > 0 and lines[#lines]:match("^%s*$") do
      lines[#lines] = nil
    end
    local start_idx = math.max(1, #lines - 79)
    local tail = {}
    for i = start_idx, #lines do
      tail[#tail + 1] = lines[i]
    end
    local snippet = "```\n" .. table.concat(tail, "\n") .. "\n```"
    local payload = note:match("%S") and (note .. "\n\n" .. snippet) or snippet

    assert(rex.block.call(terminal, "write", {
      session_id = target.session_id,
      block_id = target.block_id,
      data = payload,
    }))
    rex.session.focus_block({ session_id = target.session_id, block_id = target.block_id })
    rex.client.queue("session.select", { session_id = target.session_id, window_id = target.window_id })
    return { target = target.block_id, lines = #tail }
  end,
})
rex.bind("ctrl+a>s", "send_scrollback_to_agent")

rex.action({
  name = "floating_lazygit",
  title = "Open Floating Lazygit",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    if not info then
      error("Current pane is not in a git repository: " .. directory, 0)
    end
    return open_floating(ctx.block_id, "Lazygit", info.root, { "lazygit" })
  end,
})
rex.bind("ctrl+a>shift+g", "floating_lazygit")

rex.action({
  name = "new_worktree_session",
  title = "New Git Worktree Session…",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    if not info then
      error("Current pane is not in a git repository: " .. directory, 0)
    end
    local branches_out = git_stdout(
      info.root,
      "for-each-ref",
      "--sort=-committerdate",
      "--format=%(refname:short)",
      "refs/heads"
    ) or ""
    local items = {}
    for branch in branches_out:gmatch("[^\n]+") do
      items[#items + 1] = {
        id = branch,
        title = branch,
        detail = branch == info.branch and "current" or nil,
        icon = "branch",
      }
    end
    local selection = rex.ui.pick({
      title = "New Worktree Session",
      placeholder = "Pick a branch or type a new branch name",
      items = items,
      allow_other = true,
    })
    if not selection then
      return
    end
    local branch = type(selection) == "table" and selection.text or selection
    branch = branch:gsub("^%s+", ""):gsub("%s+$", "")
    if branch == "" then
      return
    end

    local repo_name = info.root:match("([^/]+)$") or "repo"
    local parent_dir = info.root:match("^(.+)/[^/]+$") or directory
    local slug = branch:gsub("[^%w._-]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    local worktree_dir = parent_dir .. "/" .. repo_name .. "-" .. slug
    local dir_exists = rex.exec({ "test", "-d", worktree_dir }, { timeout = 2 })
    if not (dir_exists and dir_exists.ok) then
      local has_branch = git_stdout(info.root, "show-ref", "--verify", "--quiet", "refs/heads/" .. branch) ~= nil
      local argv = has_branch and { "git", "-C", info.root, "worktree", "add", worktree_dir, branch }
        or { "git", "-C", info.root, "worktree", "add", "-b", branch, worktree_dir }
      local created_wt = exec_with_path(argv, { timeout = 10 })
      if not (created_wt and created_wt.ok) then
        error((created_wt and created_wt.stderr ~= "" and created_wt.stderr) or "git worktree add failed", 0)
      end
    end

    local label = repo_name .. "-" .. slug
    local created = assert(rex.call("session.create", {
      label = label,
      initial_windows = {
        {
          window_label = slug,
          layout = project_window_layout(worktree_dir, "Antigravity", "agy"),
        },
      },
    }))
    local window_id = created.initial_windows and created.initial_windows[1] and created.initial_windows[1].window_id
    rex.client.queue("session.select", { session_id = created.session_id, window_id = window_id })
    return created
  end,
})
rex.bind("ctrl+a>w", "new_worktree_session")

rex.action({
  name = "open_changed_files",
  title = "Open Changed Git Files in Neovim…",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    if not info then
      error("Current pane is not in a git repository: " .. directory, 0)
    end
    local result = exec_with_path({ "git", "-C", info.root, "status", "--porcelain" }, { timeout = 3 })
    if not (result and result.ok) or result.stdout == "" then
      error("Working tree is clean in " .. info.root, 0)
    end
    local items = {}
    for line in result.stdout:gmatch("[^\n]+") do
      local status = line:sub(1, 2)
      local rel = line:sub(4)
      local renamed = rel:match(" %-> (.+)$")
      if renamed then
        rel = renamed
      end
      rel = rel:gsub('^"', ""):gsub('"$', "")
      if not status:find("D") and rel ~= "" and rel:sub(-1) ~= "/" then
        local full_path = info.root .. "/" .. rel
        local basename = rel:match("([^/]+)$") or rel
        local parent = rel:match("^(.+)/[^/]+$")
        items[#items + 1] = {
          id = full_path,
          title = basename,
          subtitle = parent,
          detail = status:gsub("^%s+", ""),
          icon = "document",
        }
      end
    end
    if #items == 0 then
      error("No non-deleted changed files to open", 0)
    end

    local selected = rex.ui.pick({
      title = "Open Changed Files in Neovim",
      placeholder = "Tick files to open (Cmd+Return to confirm)",
      multiple = true,
      confirm = "Open in Neovim",
      items = items,
    })
    if not selected or #selected == 0 then
      return
    end

    local opened_existing = false
    for _, path in ipairs(selected) do
      if open_in_editor(ctx.block_id, path, nil) then
        opened_existing = true
      end
    end
    if opened_existing then
      return { opened = #selected }
    end

    local nvim_cmd = { "nvim", "--" }
    for _, path in ipairs(selected) do
      nvim_cmd[#nvim_cmd + 1] = path
    end
    return assert(rex.session.new_split({
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = pane("Editor", info.root, nvim_cmd),
    }))
  end,
})
rex.bind("ctrl+a>d", "open_changed_files")

rex.action({
  name = "open_project_session",
  title = "Switch / Open Project Session (zoxide)…",
  run = function(ctx)
    local _, home = pane_info(ctx.block_id)
    local result = exec_with_path({ "zoxide", "query", "-l" }, { timeout = 2 })
    if not (result and result.ok) or result.stdout == "" then
      error("zoxide returned no directories", 0)
    end
    local listed = assert(rex.call("session.list", {}))
    local sessions_by_label = {}
    for _, session in ipairs(listed.sessions or {}) do
      sessions_by_label[session.label] = session
    end

    local items = {}
    for dir in result.stdout:gmatch("[^\n]+") do
      local name = dir:match("([^/]+)$") or dir
      local display = (home and dir:sub(1, #home + 1) == home .. "/") and ("~" .. dir:sub(#home + 1)) or dir
      items[#items + 1] = {
        id = dir,
        title = name,
        subtitle = display,
        detail = sessions_by_label[name] and "open" or nil,
        icon = "folder",
      }
      if #items == 100 then
        break
      end
    end

    local selection = rex.ui.pick({
      title = "Open Project Session",
      placeholder = "Filter zoxide projects",
      items = items,
    })
    if not selection then
      return
    end

    local name = selection:match("([^/]+)$") or selection
    local existing = sessions_by_label[name]
    if existing then
      rex.client.queue("session.select", { session_id = existing.session_id })
      return existing
    end

    local created = assert(rex.call("session.create", {
      label = name,
      initial_windows = {
        {
          window_label = name,
          layout = pane("Shell", selection),
        },
      },
    }))
    local window_id = created.initial_windows and created.initial_windows[1] and created.initial_windows[1].window_id
    rex.client.queue("session.select", { session_id = created.session_id, window_id = window_id })
    return created
  end,
})
rex.bind("ctrl+a>o", "open_project_session")

rex.action({
  name = "open_url_reference",
  title = "Open URL from Scrollback…",
  run = function(ctx)
    local text = read_scrollback(ctx.block_id, "text")
    local vt = read_scrollback(ctx.block_id, "vt")
    local urls = {}

    local function clean_url(url)
      return (url:gsub("[.,;:!?%)%]'\">`%}%*]+$", ""))
    end

    for token in text:gmatch("%S+") do
      local url = token:match("(https?://[^%s%)%]}>\"'`]+)")
      if url then
        url = clean_url(url)
        if #url > 10 then
          urls[#urls + 1] = url
        end
      end
    end
    for url in vt:gmatch("\27%]8;[^;\27\7]*;(https?://[^\27\7]+)") do
      urls[#urls + 1] = clean_url(url)
    end

    local items, seen = {}, {}
    for index = #urls, 1, -1 do
      local url = urls[index]
      if not seen[url] then
        seen[url] = true
        local host = url:match("^https?://([^/]+)") or url
        local path = url:match("^https?://[^/]+(/.*)$")
        items[#items + 1] = {
          id = url,
          title = host .. (path or ""),
          subtitle = host,
          icon = "globe",
        }
        if #items == 200 then
          break
        end
      end
    end
    if #items == 0 then
      error("No HTTP(S) URLs found in this pane", 0)
    end

    local selection = rex.ui.pick({
      title = "Open URL in Browser",
      placeholder = "Filter URLs from scrollback",
      items = items,
    })
    if not selection then
      return
    end
    local opened = rex.exec({ "open", selection }, { timeout = 2 })
    if not (opened and opened.ok) then
      error("Could not open URL: " .. selection, 0)
    end
    return { url = selection }
  end,
})
rex.bind("ctrl+a>u", "open_url_reference")

rex.action({
  name = "open_listening_port",
  title = "Open Listening Dev Server Port…",
  run = function(ctx)
    local listed = assert(rex.call("session.list", {}))
    local entries = {}
    for _, session in ipairs(listed.sessions or {}) do
      local view = session_view(session.session_id)
      if view then
        for _, window in ipairs(view.windows or {}) do
          for _, layer in ipairs(window.layers or {}) do
            for _, block in ipairs(layer.blocks or {}) do
              if block.creator_name == terminal then
                local reply = rex.block.call(terminal, "ports", {
                  session_id = session.session_id,
                  block_id = block.block_id,
                })
                if reply and reply.ports and #reply.ports > 0 then
                  local procs = {}
                  for _, proc in ipairs(reply.processes or {}) do
                    procs[proc.pid] = proc
                  end
                  for _, port_entry in ipairs(reply.ports) do
                    if port_entry.protocol == "tcp" then
                      local proc = port_entry.pid and procs[port_entry.pid]
                      local proc_name = (proc and (proc.script or proc.argv0 or proc.name)) or "server"
                      proc_name = proc_name:match("([^/]+)$") or proc_name
                      entries[#entries + 1] = {
                        port = port_entry.port,
                        address = port_entry.address,
                        proc = proc_name,
                        session_label = session.label,
                        same_session = session.session_id == ctx.session_id,
                      }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if #entries == 0 then
      error("No listening TCP ports found in any Rex pane", 0)
    end
    table.sort(entries, function(a, b)
      if a.same_session ~= b.same_session then
        return a.same_session
      end
      return a.port < b.port
    end)

    local items, seen = {}, {}
    for _, entry in ipairs(entries) do
      local url = "http://localhost:" .. entry.port
      if not seen[url] then
        seen[url] = true
        items[#items + 1] = {
          id = url,
          title = ":" .. entry.port .. " — " .. entry.proc,
          subtitle = entry.session_label .. " (" .. entry.address .. ")",
          detail = entry.same_session and "this session" or entry.session_label,
          icon = "server",
        }
      end
    end

    local selection = rex.ui.pick({
      title = "Open Listening Port",
      placeholder = "Filter active dev servers",
      items = items,
    })
    if not selection then
      return
    end
    local opened = rex.exec({ "open", selection }, { timeout = 2 })
    if not (opened and opened.ok) then
      error("Could not open " .. selection, 0)
    end
    return { url = selection }
  end,
})
rex.bind("ctrl+a>shift+l", "open_listening_port")

rex.action({
  name = "run_project_task",
  title = "Run Project Task (just / make)…",
  run = function(ctx)
    local directory = cwd(ctx.block_id)
    local info = git_info(directory)
    local items, by_id = {}, {}

    local function find_file(names)
      for _, base in ipairs({ directory, info and info.root }) do
        if base then
          for _, name in ipairs(names) do
            local candidate = base .. "/" .. name
            if existing_files({ candidate })[candidate] then
              return candidate, base
            end
          end
        end
      end
      return nil
    end

    local justfile_path, just_dir = find_file({ "justfile", "Justfile", ".justfile" })
    if justfile_path then
      local summary = exec_with_path({ "just", "--justfile", justfile_path, "--summary" }, { timeout = 2 })
      if summary and summary.ok then
        for recipe in summary.stdout:gmatch("%S+") do
          local id = "just:" .. recipe
          items[#items + 1] = {
            id = id,
            title = recipe,
            subtitle = "just " .. recipe,
            detail = "just",
            icon = "gear",
          }
          by_id[id] = { dir = just_dir, cmd = { "just", recipe }, label = "just " .. recipe }
        end
      end
    end

    local makefile_path, make_dir = find_file({ "Makefile", "makefile", "GNUmakefile" })
    if makefile_path then
      local file = io.open(makefile_path, "r")
      if file then
        local seen_targets = {}
        for line in file:lines() do
          local target = line:match("^([%w][%w._%-]*):[^=]") or line:match("^([%w][%w._%-]*):$")
          if target and not seen_targets[target] then
            seen_targets[target] = true
            local id = "make:" .. target
            items[#items + 1] = {
              id = id,
              title = target,
              subtitle = "make " .. target,
              detail = "make",
              icon = "gear",
            }
            by_id[id] = { dir = make_dir, cmd = { "make", target }, label = "make " .. target }
          end
        end
        file:close()
      end
    end

    if #items == 0 then
      error("No justfile or Makefile tasks found from " .. directory, 0)
    end

    local selection = rex.ui.pick({
      title = "Run Project Task",
      placeholder = "Filter just / make targets",
      items = items,
    })
    if not selection then
      return
    end
    local chosen = by_id[selection]
    if not chosen then
      return
    end
    return assert(rex.session.new_split({
      anchor_id = ctx.block_id,
      direction = "vertical",
      side = "after",
      focus = true,
      layout = pane(chosen.label, chosen.dir, chosen.cmd, { exit = { on_completion = false } }),
    }))
  end,
})
rex.bind("ctrl+a>t", "run_project_task")

rex.action({
  name = "floating_scratchpad",
  title = "Open Floating Scratchpad Shell",
  run = function(ctx)
    return open_floating(ctx.block_id, "Scratchpad", cwd(ctx.block_id), nil, { 0.11, 0.16, 0.78, 0.68 })
  end,
})
rex.bind("ctrl+a>space", "floating_scratchpad")
