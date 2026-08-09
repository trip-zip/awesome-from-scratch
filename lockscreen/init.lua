-- Minimal lockscreen following somewm's lock API pattern
-- See: https://github.com/trip-zip/somewm/pull/201

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local M = {}
local password = ""
local surfaces = {} -- keyed by screen
local interactive_screen = nil
local grab = nil
local failed_attempts = 0
local caps_lock_on = false

-- Widget references (built in build_ui)
local greeting = nil
local clock = nil
local date_widget = nil
local password_dots = nil
local caps_warning = nil
local status_text = nil
local battery_widget = nil
local layout = nil
local status_container = nil

-- Color references (set in build_ui)
local colors = {}

-- Count UTF-8 codepoints in a string (LuaJIT lacks the utf8 library)
local function utf8_len(s)
  local count = 0
  for i = 1, #s do
    local b = s:byte(i)
    if b < 0x80 or b >= 0xC0 then
      count = count + 1
    end
  end
  return count
end

-- Get time-based greeting
local function get_greeting()
  local hour = tonumber(os.date("%H"))
  local user = os.getenv("USER") or "user"
  local greeting_text

  if hour >= 5 and hour < 12 then
    greeting_text = "Good morning"
  elseif hour >= 12 and hour < 18 then
    greeting_text = "Good afternoon"
  elseif hour >= 18 and hour < 22 then
    greeting_text = "Good evening"
  else
    greeting_text = "Good night"
  end

  return greeting_text .. ", " .. user
end

-- Get battery icon based on percentage
local function get_battery_icon(percent)
  if percent >= 90 then
    return "󰁹"
  elseif percent >= 80 then
    return "󰂂"
  elseif percent >= 70 then
    return "󰂁"
  elseif percent >= 60 then
    return "󰂀"
  elseif percent >= 50 then
    return "󰁿"
  elseif percent >= 40 then
    return "󰁾"
  elseif percent >= 30 then
    return "󰁽"
  elseif percent >= 20 then
    return "󰁼"
  elseif percent >= 10 then
    return "󰁻"
  else
    return "󰁺"
  end
end

-- Get battery color based on percentage
local function get_battery_color(percent)
  if percent > 50 then
    return colors.soft_green
  elseif percent > 20 then
    return colors.soft_yellow
  else
    return colors.soft_red
  end
end

-- Update battery display
local function update_battery()
  if not battery_widget then
    return
  end

  awful.spawn.easy_async_with_shell(
    [[
        cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || \
        cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || \
        echo "?"
    ]],
    function(stdout)
      local percent = tonumber(stdout:match("(%d+)")) or 0
      local icon = get_battery_icon(percent)
      battery_widget.markup =
        string.format('<span foreground="%s">%s %d%%</span>', get_battery_color(percent), icon, percent)
    end
  )
end

-- Update the status line; errors show in red
local function set_status(text, is_error)
  status_text.text = text
  if status_container then
    status_container.fg = is_error and colors.soft_red or colors.grey1
  end
end

-- The recurring "N failed attempt(s)" status line
local function show_attempts_status()
  if failed_attempts > 0 then
    local plural = failed_attempts == 1 and "attempt" or "attempts"
    set_status(string.format("%d failed %s", failed_attempts, plural), true)
  else
    set_status("Enter password to unlock", false)
  end
end

-- Render the caps lock warning from tracked state
local function update_caps_warning()
  if caps_lock_on then
    caps_warning.markup = string.format('<span foreground="%s">⚠ Caps Lock is ON</span>', colors.soft_orange)
  else
    caps_warning.markup = ""
  end
end

-- Read the kernel LED state once (when the lock activates); afterwards the
-- keygrabber tracks Caps_Lock presses itself instead of spawning a shell
-- process for every character typed.
local function read_caps_lock_state()
  awful.spawn.easy_async_with_shell(
    [[
        for f in /sys/class/leds/*capslock*/brightness; do
            [ -f "$f" ] && cat "$f" && exit
        done
        echo "0"
    ]],
    function(stdout)
      caps_lock_on = tonumber(stdout:match("(%d+)")) == 1
      update_caps_warning()
    end
  )
end

-- Build all widgets and the main layout for the interactive screen
local function build_ui()
  -- Local shorthand for the theme colors this module uses
  colors.bg = beautiful.lockscreen_bg or beautiful.bg_normal
  colors.fg = beautiful.lockscreen_fg or beautiful.fg_normal
  colors.grey1 = beautiful.fg_dim
  colors.grey2 = beautiful.lockscreen_input_bg or beautiful.bg_focus
  colors.orange = beautiful.primary_color
  colors.soft_orange = beautiful.primary_color_hover
  colors.soft_red = beautiful.urgent_hover
  colors.soft_green = beautiful.active_hover
  colors.soft_yellow = beautiful.accent_hover

  -- Greeting widget (time-based)
  greeting = wibox.widget({
    text = get_greeting(),
    font = beautiful.font_size(16),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Clock widget (large, prominent)
  clock = wibox.widget({
    format = "%H:%M",
    font = beautiful.font_size(96, "Bold"),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Date widget (subdued gray)
  date_widget = wibox.widget({
    format = "%A, %B %d",
    font = beautiful.font_size(16),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Password dots display
  password_dots = wibox.widget({
    text = "",
    font = beautiful.font_size(20),
    halign = "center",
    valign = "center",
    widget = wibox.widget.textbox,
  })

  -- Caps Lock warning (orange when active)
  caps_warning = wibox.widget({
    markup = "",
    font = beautiful.font_size(11),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Status text (shows failed attempts when applicable)
  status_text = wibox.widget({
    text = "Enter password to unlock",
    font = beautiful.font_size(11),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Battery indicator
  battery_widget = wibox.widget({
    markup = "󰁿 ---%",
    font = beautiful.font_size(11),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Password input box with orange border
  local input_box = wibox.widget({
    {
      {
        password_dots,
        left = 24,
        right = 24,
        top = 14,
        bottom = 14,
        widget = wibox.container.margin,
      },
      bg = colors.grey2,
      shape = gears.shape.rectangle,
      widget = wibox.container.background,
    },
    color = colors.orange,
    shape = gears.shape.rectangle,
    margins = 2,
    widget = wibox.container.margin,
  })

  -- Wrap input box to control width
  local input_container = wibox.widget({
    input_box,
    forced_width = 320,
    forced_height = 54,
    widget = wibox.container.constraint,
  })

  -- Main layout
  layout = wibox.widget({
    {
      {
        -- Greeting (time-based)
        {
          greeting,
          fg = colors.grey1,
          widget = wibox.container.background,
        },
        -- Clock (bright foreground)
        {
          clock,
          fg = colors.fg,
          widget = wibox.container.background,
        },
        -- Date (subdued gray)
        {
          date_widget,
          fg = colors.grey1,
          widget = wibox.container.background,
        },
        -- Spacer
        {
          forced_height = 40,
          widget = wibox.container.background,
        },
        -- Input box
        {
          input_container,
          halign = "center",
          widget = wibox.container.place,
        },
        -- Caps Lock warning (below input)
        {
          caps_warning,
          top = 8,
          widget = wibox.container.margin,
        },
        -- Status text (starts gray, turns red on error)
        {
          {
            status_text,
            id = "status_container",
            fg = colors.grey1,
            widget = wibox.container.background,
          },
          top = 8,
          widget = wibox.container.margin,
        },
        -- Battery indicator
        {
          battery_widget,
          top = 24,
          widget = wibox.container.margin,
        },
        spacing = 4,
        layout = wibox.layout.fixed.vertical,
      },
      halign = "center",
      valign = "center",
      widget = wibox.container.place,
    },
    bg = colors.bg,
    fg = colors.fg,
    widget = wibox.container.background,
  })

  -- Store status container for color changes
  status_container = layout:get_children_by_id("status_container")[1]
end

-- Create a plain cover wibox for a non-interactive screen
local function create_cover(s)
  local wb = wibox({
    visible = false,
    ontop = true,
    bg = colors.bg,
    x = s.geometry.x,
    y = s.geometry.y,
    width = s.geometry.width,
    height = s.geometry.height,
  })
  awesome.add_lock_cover(wb)
  return wb
end

-- Create the interactive wibox for the password screen
local function create_interactive(s)
  local wb = wibox({
    visible = false,
    ontop = true,
    bg = colors.bg,
    x = s.geometry.x,
    y = s.geometry.y,
    width = s.geometry.width,
    height = s.geometry.height,
    widget = layout,
  })
  awesome.set_lock_surface(wb)
  return wb
end

-- Set visibility on all surfaces
local function set_visibility_all(visible)
  for _, wb in pairs(surfaces) do
    wb.visible = visible
  end
end

-- Handle one key while locked
local function handle_key(key)
  if key == "Caps_Lock" then
    caps_lock_on = not caps_lock_on
    update_caps_warning()
  elseif key == "Return" then
    set_status("Authenticating...", false)

    gears.timer.start_new(0.05, function()
      if awesome.authenticate(password) then
        failed_attempts = 0 -- Reset on success
        awesome.unlock()
      else
        -- Just reset input; lock::auth_failed handles the rest
        password = ""
        password_dots.text = ""
      end
      return false
    end)
  elseif key == "BackSpace" then
    if #password > 0 then
      -- Walk backwards past UTF-8 continuation bytes
      local i = #password
      while i > 1 and password:byte(i) >= 0x80 and password:byte(i) < 0xC0 do
        i = i - 1
      end
      password = password:sub(1, i - 1)
    end
    password_dots.text = string.rep("\xE2\x97\x8F", utf8_len(password))
  elseif key == "Escape" then
    password = ""
    password_dots.text = ""
  elseif #key >= 1 and key:byte(1) >= 0x20 then
    if #password > 256 then
      return
    end
    -- Only append single-codepoint keys; reject named keys like "Shift_R"
    if utf8_len(key) > 1 then
      return
    end
    password = password .. key
    password_dots.text = string.rep("\xE2\x97\x8F", utf8_len(password))
  end
end

-- Grab all keyboard input for the password prompt
local function start_grabber()
  grab = awful.keygrabber({
    autostart = true,
    stop_key = nil,
    mask_modkeys = true,
    keypressed_callback = function(_, _, key, _)
      handle_key(key)
    end,
  })
end

-- The lock was activated: reset input, refresh info widgets, grab the keyboard
local function on_lock_activate()
  password = ""
  password_dots.text = ""
  caps_warning.markup = ""

  -- Update greeting (in case time changed)
  greeting.text = get_greeting()

  -- Update battery and caps lock state
  update_battery()
  read_caps_lock_state()

  show_attempts_status()
  set_visibility_all(true)
  start_grabber()
end

-- The session was unlocked: hide everything and release the keyboard
local function on_lock_deactivate()
  set_visibility_all(false)
  password = ""
  if grab then
    grab:stop()
    grab = nil
  end
end

-- Sole owner of the failed_attempts counter
local function on_auth_failed()
  failed_attempts = failed_attempts + 1
  local plural = failed_attempts == 1 and "attempt" or "attempts"
  set_status(string.format("Authentication failed (%d %s)", failed_attempts, plural), true)
  password = ""
  password_dots.text = ""

  gears.timer.start_new(2, function()
    if awesome.locked then
      show_attempts_status()
    end
    return false
  end)
end

-- A screen appeared while the module is active; cover it
local function on_screen_added(s)
  if not surfaces[s] then
    surfaces[s] = create_cover(s)
    if awesome.locked then
      surfaces[s].visible = true
    end
  end
end

-- A screen disappeared; if it held the password prompt, migrate the prompt
local function on_screen_removed(s)
  local wb = surfaces[s]
  if not wb then
    return
  end

  wb.visible = false
  if s ~= interactive_screen then
    awesome.remove_lock_cover(wb)
    surfaces[s] = nil
    return
  end

  -- Interactive screen removed during lock - migrate
  awesome.clear_lock_surface()
  surfaces[s] = nil
  interactive_screen = screen.primary or screen[1]
  if interactive_screen then
    if surfaces[interactive_screen] then
      -- Convert existing cover to interactive
      awesome.remove_lock_cover(surfaces[interactive_screen])
    end
    surfaces[interactive_screen] = create_interactive(interactive_screen)
    if awesome.locked then
      surfaces[interactive_screen].visible = true
    end
  end
end

function M.init()
  build_ui()

  -- Build surfaces for all screens
  interactive_screen = screen.primary
  for s in screen do
    if s == interactive_screen then
      surfaces[s] = create_interactive(s)
    else
      surfaces[s] = create_cover(s)
    end
  end

  screen.connect_signal("added", on_screen_added)
  screen.connect_signal("removed", on_screen_removed)
  awesome.connect_signal("lock::activate", on_lock_activate)
  awesome.connect_signal("lock::deactivate", on_lock_deactivate)
  awesome.connect_signal("lock::auth_failed", on_auth_failed)
end

return M
