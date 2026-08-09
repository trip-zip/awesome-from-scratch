local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local modal = require("modal")

local launcher = {}

-- Flip this to true to watch the launcher work. It reports .desktop scanning, icon
-- cache hits, and timings on stderr (`~/.cache/somewm/stderr`).
--
-- Leave it on for a session the first time you build this. The launcher does a
-- synchronous directory walk on a cold cache, and seeing that number is the whole
-- reason the cache exists.
local debug_launcher = false

local function log(fmt, ...)
  if debug_launcher then
    io.stderr:write("[launcher] " .. string.format(fmt, ...) .. "\n")
  end
end

local function log_time(label, start_time)
  local elapsed = (os.clock() - start_time) * 1000
  log("%s: %.2fms", label, elapsed)
  return elapsed
end

-- Icon cache for fast lookups across sessions.
-- `get_cache_dir()` resolves to ~/.cache/somewm (or ~/.cache/awesome) and creates the
-- directory if it is missing, so this cannot fail on a fresh machine.
--
-- The format is one "name<TAB>path" line per entry. Icon names cannot contain
-- tabs or newlines, so nothing needs escaping; an empty path records a known
-- miss so we never re-run the expensive search for an icon that isn't there.
local icon_cache = {}
local icon_cache_path = gears.filesystem.get_cache_dir() .. "launcher-icons.cache"
local icon_cache_dirty = false

local function load_icon_cache()
  local file = io.open(icon_cache_path, "r")
  if not file then
    return false
  end

  local count = 0
  for line in file:lines() do
    local name, path = line:match("^([^\t]+)\t(.*)$")
    if name then
      icon_cache[name] = path ~= "" and path or false -- false = known missing
      count = count + 1
    end
  end
  file:close()
  log("Loaded icon cache: %d entries", count)
  return true
end

local function save_icon_cache()
  if not icon_cache_dirty then
    return
  end
  local file = io.open(icon_cache_path, "w")
  if not file then
    return
  end
  for name, path in pairs(icon_cache) do
    file:write(name, "\t", path or "", "\n")
  end
  file:close()
  icon_cache_dirty = false
  log("Saved icon cache")
end

-- State
local search_text = ""
local selected_index = 1
local filtered_apps = {}
local all_apps = {}

-- Configuration
local config = {
  width = 500,
  max_results = 8,
  icon_size = 40,
  item_height = 50,
  margin = 16,
}

--- Fuzzy match function
-- Returns a score (higher is better match), or nil if no match
local function fuzzy_match(pattern, str)
  if not pattern or pattern == "" then
    return 1 -- Empty pattern matches everything
  end

  pattern = pattern:lower()
  str = str:lower()

  -- Exact substring match (highest priority)
  if str:find(pattern, 1, true) then
    -- Earlier match = higher score
    local pos = str:find(pattern, 1, true)
    return 1000 - pos
  end

  -- Fuzzy match
  local score = 0
  local pattern_idx = 1
  local last_match = 0

  for i = 1, #str do
    if pattern_idx <= #pattern and str:sub(i, i) == pattern:sub(pattern_idx, pattern_idx) then
      -- Bonus for consecutive matches
      if i == last_match + 1 then
        score = score + 10
      else
        score = score + 1
      end
      -- Bonus for matching at word boundaries
      if i == 1 or str:sub(i - 1, i - 1):match("[%s%-_]") then
        score = score + 5
      end
      pattern_idx = pattern_idx + 1
      last_match = i
    end
  end

  -- Return score only if entire pattern was matched
  if pattern_idx > #pattern then
    return score
  end

  return nil
end

--- Parse a single .desktop file
local function parse_desktop_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local app = {}
  local in_desktop_entry = false

  for line in file:lines() do
    if line:match("^%[Desktop Entry%]") then
      in_desktop_entry = true
    elseif line:match("^%[") then
      in_desktop_entry = false
    elseif in_desktop_entry then
      local key, value = line:match("^([^=]+)=(.*)$")
      if key and value then
        if key == "Name" and not app.name then
          app.name = value
        elseif key == "Exec" then
          -- Remove field codes like %f, %F, %u, %U, etc.
          app.exec = value:gsub("%%[fFuUdDnNickvm]", ""):gsub("%s+$", "")
        elseif key == "Icon" then
          app.icon = value
        elseif key == "Comment" then
          app.comment = value
        elseif key == "NoDisplay" and value == "true" then
          file:close()
          return nil
        elseif key == "Hidden" and value == "true" then
          file:close()
          return nil
        elseif key == "Type" and value ~= "Application" then
          file:close()
          return nil
        end
      end
    end
  end

  file:close()

  if app.name and app.exec then
    app.comment = app.comment or ""
    return app
  end
  return nil
end

-- Known icon overrides for apps with non-standard icon names
local icon_overrides = {
  ["code"] = "visual-studio-code",
  ["code-oss"] = "visual-studio-code",
  ["codium"] = "vscodium",
  ["blueman-device"] = "blueman",
  ["blueman-adapters"] = "blueman",
}

-- The flattened, priority-ordered list of directories an icon can live in.
-- Built once: checking which base/theme/size/subdir combinations actually
-- exist on this machine turns thousands of file stats per icon lookup into a
-- short walk over a few dozen real directories.
local icon_search_dirs = nil

local function get_icon_search_dirs()
  if icon_search_dirs then
    return icon_search_dirs
  end
  icon_search_dirs = {}

  local base_dirs = {
    os.getenv("HOME") .. "/.local/share/icons",
    os.getenv("HOME") .. "/.icons",
    "/usr/share/icons",
    "/usr/local/share/icons",
  }
  local themes = { beautiful.icon_theme or "hicolor", "Papirus", "Adwaita", "hicolor", "breeze", "gnome" }
  local sizes = { "scalable", "256x256", "128x128", "96x96", "64x64", "48x48", "32x32", "24x24", "22x22" }
  local subdirs = { "apps", "applications", "devices", "categories", "status", "mimetypes" }

  local seen_theme = {}
  for _, base in ipairs(base_dirs) do
    if gears.filesystem.dir_readable(base) then
      for _, theme_name in ipairs(themes) do
        local theme_dir = base .. "/" .. theme_name
        if not seen_theme[theme_dir] and gears.filesystem.dir_readable(theme_dir) then
          seen_theme[theme_dir] = true
          for _, size in ipairs(sizes) do
            for _, subdir in ipairs(subdirs) do
              local dir = theme_dir .. "/" .. size .. "/" .. subdir
              if gears.filesystem.dir_readable(dir) then
                table.insert(icon_search_dirs, dir)
              end
            end
          end
        end
      end
    end
  end

  for _, dir in ipairs({ "/usr/share/pixmaps", "/usr/local/share/pixmaps" }) do
    if gears.filesystem.dir_readable(dir) then
      table.insert(icon_search_dirs, dir)
    end
  end

  log("icon search: %d real directories", #icon_search_dirs)
  return icon_search_dirs
end

--- Find icon path from icon name (with persistent cache)
local function find_icon(icon_name)
  if not icon_name then
    return nil
  end

  -- Check for overrides first
  local lower_name = icon_name:lower()
  icon_name = icon_overrides[lower_name] or icon_name

  -- If it's already an absolute path, return it if readable
  if icon_name:match("^/") then
    if gears.filesystem.file_readable(icon_name) then
      return icon_name
    end
    return nil
  end

  -- Check cache first
  if icon_cache[icon_name] ~= nil then
    local cached = icon_cache[icon_name]
    return cached ~= false and cached or nil -- false means known missing
  end

  -- Walk the real icon directories (only on cache miss)
  local extensions = { ".svg", ".png", ".xpm", "" }
  for _, dir in ipairs(get_icon_search_dirs()) do
    for _, ext in ipairs(extensions) do
      local path = dir .. "/" .. icon_name .. ext
      if gears.filesystem.file_readable(path) then
        icon_cache[icon_name] = path
        icon_cache_dirty = true
        return path
      end
    end
  end

  -- Cache the miss
  icon_cache[icon_name] = false
  icon_cache_dirty = true
  return nil
end

--- Load applications from .desktop files.
-- The directory walk runs asynchronously so the first launcher open never
-- blocks the compositor; `on_done` fires once the app list is ready.
local apps_loading = false

local function load_apps(on_done)
  if apps_loading then
    return
  end
  apps_loading = true

  local load_start = os.clock()
  log("load_apps() START")

  -- Load icon cache from disk
  if load_icon_cache() then
    log("Using cached icons")
  end

  -- Desktop file directories
  local desktop_dirs = {
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.getenv("HOME") .. "/.local/share/applications",
  }

  -- Phase 1: Find all desktop files, off the main loop. find(1) complains
  -- about directories that don't exist; stderr is simply ignored.
  local find_start = os.clock()
  local cmd = { "find" }
  for _, dir in ipairs(desktop_dirs) do
    table.insert(cmd, dir)
  end
  table.insert(cmd, "-name")
  table.insert(cmd, "*.desktop")

  awful.spawn.easy_async(cmd, function(stdout)
    log_time("  find command", find_start)

    all_apps = {}
    local seen = {} -- Avoid duplicates
    local icons_found = 0
    local icons_missing = 0

    -- Phase 2: Parse files and resolve icons
    local parse_start = os.clock()
    for path in stdout:gmatch("[^\n]+") do
      local basename = path:match("([^/]+)$")
      if basename and not seen[basename] then
        seen[basename] = true
        local app = parse_desktop_file(path)
        if app then
          local resolved_icon = find_icon(app.icon)
          if resolved_icon then
            icons_found = icons_found + 1
          else
            icons_missing = icons_missing + 1
          end
          app.icon = resolved_icon
          table.insert(all_apps, app)
        end
      end
    end
    log_time("  parse + icons", parse_start)
    log("  - icons found: %d, missing: %d", icons_found, icons_missing)

    -- Sort alphabetically by default
    table.sort(all_apps, function(a, b)
      return a.name:lower() < b.name:lower()
    end)

    log_time("load_apps() TOTAL", load_start)
    log("  - loaded %d apps", #all_apps)

    -- Save icon cache if modified
    save_icon_cache()

    apps_loading = false
    if on_done then
      on_done()
    end
  end)
end

--- Filter apps based on search text
local function filter_apps()
  filtered_apps = {}

  if search_text == "" then
    -- Show all apps (limited)
    for i = 1, math.min(config.max_results, #all_apps) do
      table.insert(filtered_apps, all_apps[i])
    end
  else
    -- Fuzzy filter and sort by match score
    local scored = {}
    for _, app in ipairs(all_apps) do
      local name_score = fuzzy_match(search_text, app.name)
      local comment_score = fuzzy_match(search_text, app.comment)
      local score = math.max(name_score or 0, (comment_score or 0) * 0.5)

      if score > 0 then
        table.insert(scored, { app = app, score = score })
      end
    end

    table.sort(scored, function(a, b)
      return a.score > b.score
    end)

    for i = 1, math.min(config.max_results, #scored) do
      table.insert(filtered_apps, scored[i].app)
    end
  end

  -- Reset selection
  selected_index = math.min(selected_index, math.max(1, #filtered_apps))
end

-- Theme accent colors for initial-based fallback icons
local initial_colors = {
  beautiful.primary_color,
  beautiful.highlight,
  beautiful.active,
  beautiful.accent,
  beautiful.urgent,
  beautiful.highlight_hover,
}

-- Get a consistent color for an app based on its name
local function get_initial_color(name)
  local sum = 0
  for i = 1, #name do
    sum = sum + string.byte(name, i)
  end
  return initial_colors[(sum % #initial_colors) + 1]
end

--- Create an app item widget
local function create_app_item(app, index)
  local is_selected = index == selected_index

  local icon_widget
  if app.icon then
    icon_widget = wibox.widget({
      image = app.icon,
      resize = true,
      forced_width = config.icon_size,
      forced_height = config.icon_size,
      widget = wibox.widget.imagebox,
    })
  else
    -- Fallback: styled initial (first letter of app name)
    local initial = app.name:sub(1, 1):upper()
    local bg_color = get_initial_color(app.name)

    icon_widget = wibox.widget({
      {
        {
          text = initial,
          font = beautiful.font_size(18, "Bold"),
          halign = "center",
          valign = "center",
          widget = wibox.widget.textbox,
        },
        fg = beautiful.bg_normal, -- Dark text on colored background
        widget = wibox.container.background,
      },
      bg = bg_color,
      shape = gears.shape.rectangle,
      forced_width = config.icon_size,
      forced_height = config.icon_size,
      widget = wibox.container.background,
    })
  end

  local item = wibox.widget({
    {
      {
        icon_widget,
        {
          {
            text = app.name,
            font = beautiful.font_size(12),
            widget = wibox.widget.textbox,
          },
          {
            text = app.comment ~= "" and app.comment or app.exec:match("^%S+"),
            font = beautiful.font_size(10),
            widget = wibox.widget.textbox,
          },
          spacing = 2,
          layout = wibox.layout.fixed.vertical,
        },
        spacing = 12,
        layout = wibox.layout.fixed.horizontal,
      },
      margins = 8,
      widget = wibox.container.margin,
    },
    bg = is_selected and beautiful.primary_color or "transparent",
    fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
    shape = beautiful.shape_small,
    forced_height = config.item_height,
    widget = wibox.container.background,
  })

  -- Click to launch
  item:add_button(awful.button({}, 1, function()
    log("Click on: " .. app.name .. " -> " .. app.exec .. "")
    launcher.hide()
    awful.spawn(app.exec)
  end))

  -- Hover
  item:connect_signal("mouse::enter", function()
    selected_index = index
    launcher.refresh()
  end)

  return item
end

--- Create the search input widget
local function create_search_input()
  return wibox.widget({
    {
      {
        {
          text = "",
          font = beautiful.font_size(18),
          widget = wibox.widget.textbox,
        },
        fg = beautiful.primary_color,
        widget = wibox.container.background,
      },
      {
        id = "search_text",
        text = search_text == "" and "Search applications..." or search_text,
        font = beautiful.font_size(14),
        widget = wibox.widget.textbox,
      },
      spacing = 12,
      layout = wibox.layout.fixed.horizontal,
    },
    {
      {
        orientation = "horizontal",
        forced_height = 2,
        color = beautiful.primary_color,
        widget = wibox.widget.separator,
      },
      top = 8,
      widget = wibox.container.margin,
    },
    layout = wibox.layout.fixed.vertical,
  })
end

--- Create the results list widget
local function create_results_list()
  if #filtered_apps == 0 then
    return wibox.widget({
      {
        text = apps_loading and "Loading applications..." or "No applications found",
        font = beautiful.font_size(12),
        halign = "center",
        widget = wibox.widget.textbox,
      },
      fg = beautiful.fg_normal .. "88",
      widget = wibox.container.background,
    })
  end

  local layout = wibox.layout.fixed.vertical()
  layout.spacing = 4

  for i, app in ipairs(filtered_apps) do
    layout:add(create_app_item(app, i))
  end

  -- Wrap in a container to capture scroll events
  local container = wibox.widget({
    layout,
    widget = wibox.container.background,
  })

  container:add_button(awful.button({}, 4, function()
    -- Scroll up
    selected_index = math.max(1, selected_index - 1)
    launcher.refresh()
  end))
  container:add_button(awful.button({}, 5, function()
    -- Scroll down
    selected_index = math.min(#filtered_apps, selected_index + 1)
    launcher.refresh()
  end))

  return container
end

--- Create the main launcher widget
local function create_launcher_widget()
  local widget_start = os.clock()

  -- Calculate max height based on max_results
  local max_height = config.margin * 2 -- top + bottom margin
    + 40 -- search input area
    + 16 -- spacing
    + (config.item_height + 4) * config.max_results -- items + spacing

  local widget = wibox.widget({
    {
      {
        create_search_input(),
        {
          create_results_list(),
          top = 16,
          widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
      },
      margins = config.margin,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_normal .. "F8",
    shape = beautiful.shape,
    forced_width = config.width,
    forced_height = max_height,
    widget = wibox.container.background,
  })

  log_time("  create_launcher_widget()", widget_start)
  return widget
end

--- Launch selected app
local function launch_selected()
  log("launch_selected called, filtered_apps=" .. #filtered_apps .. " selected=" .. selected_index .. "")
  if #filtered_apps > 0 and filtered_apps[selected_index] then
    local app = filtered_apps[selected_index]
    log("Launching: " .. app.name .. " -> " .. app.exec .. "")
    launcher.hide()
    awful.spawn(app.exec)
  else
    log("No app to launch")
  end
end

-- The modal controller owns visibility, the keygrabber, Escape, and the
-- launcher::visible signal; this module supplies content and typing keys.
local controller = modal.new({
  name = "launcher",
  build_popup = function()
    return awful.popup({
      widget = create_launcher_widget(),
      screen = awful.screen.focused(),
      placement = awful.placement.centered,
      ontop = true,
      visible = false,
      bg = "#00000000",
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      shape = beautiful.shape,
    })
  end,
  on_show = function(popup)
    -- Load apps if not already loaded; the list fills in when the async scan
    -- finishes (the popup shows "Loading applications..." until then)
    if #all_apps == 0 then
      load_apps(function()
        if launcher.is_visible() then
          launcher.refresh()
        end
      end)
    else
      log("Using cached apps (%d apps)", #all_apps)
    end

    -- Reset state
    search_text = ""
    selected_index = 1
    filter_apps()

    local s = awful.screen.focused()
    popup.screen = s
    awful.placement.centered(popup, { parent = s })
    popup.widget = create_launcher_widget()
  end,
  keypressed = function(_, key)
    if key == "Return" then
      launch_selected()
    elseif key == "Up" then
      selected_index = math.max(1, selected_index - 1)
      launcher.refresh()
    elseif key == "Down" then
      selected_index = math.min(#filtered_apps, selected_index + 1)
      launcher.refresh()
    elseif key == "BackSpace" then
      search_text = search_text:sub(1, -2)
      launcher.refresh()
    elseif key == "Tab" then
      -- Tab completion - fill in selected app name
      if #filtered_apps > 0 then
        search_text = filtered_apps[selected_index].name
        launcher.refresh()
      end
    elseif #key == 1 then
      -- Single character - add to search
      search_text = search_text .. key
      launcher.refresh()
    end
  end,
})

--- Refresh the launcher display
function launcher.refresh()
  if controller.popup then
    filter_apps()
    controller.popup.widget = create_launcher_widget()
  end
end

launcher.show = controller.show
launcher.hide = controller.hide
launcher.toggle = controller.toggle
launcher.is_visible = controller.is_visible

--- Reload applications
function launcher.reload()
  load_apps()
end

return launcher
