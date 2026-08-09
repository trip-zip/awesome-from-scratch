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

-- Widget references
local greeting = nil
local clock = nil
local date_widget = nil
local password_dots = nil
local caps_warning = nil
local status_text = nil
local battery_widget = nil

-- Color references (set in init)
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

function M.init()
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

  -- Create clock widget (large, prominent)
  clock = wibox.widget({
    format = "%H:%M",
    font = beautiful.font_size(96, "Bold"),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Create date widget (subdued gray)
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
  local layout = wibox.widget({
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
  local status_container = layout:get_children_by_id("status_container")[1]

  -- Helper to update status
  local function set_status(text, is_error)
    status_text.text = text
    if status_container then
      status_container.fg = is_error and colors.soft_red or colors.grey1
    end
  end

  -- Helper to update caps lock warning (reads kernel LED state)
  local function update_caps_lock()
    awful.spawn.easy_async_with_shell(
      [[
            for f in /sys/class/leds/*capslock*/brightness; do
                [ -f "$f" ] && cat "$f" && exit
            done
            echo "0"
        ]],
      function(stdout)
        local caps_on = tonumber(stdout:match("(%d+)")) == 1
        if caps_on then
          caps_warning.markup = string.format('<span foreground="%s">⚠ Caps Lock is ON</span>', colors.soft_orange)
        else
          caps_warning.markup = ""
        end
      end
    )
  end

  -- Helper: create a plain cover wibox for a non-interactive screen
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

  -- Helper: create the interactive wibox for the password screen
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

  -- Helper: set visibility on all surfaces
  local function set_visibility_all(visible)
    for _, wb in pairs(surfaces) do
      wb.visible = visible
    end
  end

  -- Build surfaces for all screens
  interactive_screen = screen.primary
  for s in screen do
    if s == interactive_screen then
      surfaces[s] = create_interactive(s)
    else
      surfaces[s] = create_cover(s)
    end
  end

  -- Handle screen hotplug
  screen.connect_signal("added", function(s)
    if not surfaces[s] then
      surfaces[s] = create_cover(s)
      if awesome.locked then
        surfaces[s].visible = true
      end
    end
  end)

  screen.connect_signal("removed", function(s)
    local wb = surfaces[s]
    if wb then
      wb.visible = false
      if s == interactive_screen then
        -- Interactive screen removed during lock - migrate
        awesome.clear_lock_surface()
        surfaces[s] = nil
        interactive_screen = screen.primary or screen[1]
        if interactive_screen and not surfaces[interactive_screen] then
          surfaces[interactive_screen] = create_interactive(interactive_screen)
          if awesome.locked then
            surfaces[interactive_screen].visible = true
          end
        elseif interactive_screen and surfaces[interactive_screen] then
          -- Convert existing cover to interactive
          awesome.remove_lock_cover(surfaces[interactive_screen])
          surfaces[interactive_screen] = create_interactive(interactive_screen)
          if awesome.locked then
            surfaces[interactive_screen].visible = true
          end
        end
      else
        awesome.remove_lock_cover(wb)
        surfaces[s] = nil
      end
    end
  end)

  -- Handle lock activation
  awesome.connect_signal("lock::activate", function()
    password = ""
    password_dots.text = ""
    caps_warning.markup = ""

    -- Update greeting (in case time changed)
    greeting.text = get_greeting()

    -- Update battery and caps lock state
    update_battery()
    update_caps_lock()

    -- Reset or show failed attempts
    if failed_attempts > 0 then
      local plural = failed_attempts == 1 and "attempt" or "attempts"
      set_status(string.format("%d failed %s", failed_attempts, plural), true)
    else
      set_status("Enter password to unlock", false)
    end

    set_visibility_all(true)

    -- Start keygrabber
    grab = awful.keygrabber({
      autostart = true,
      stop_key = nil,
      mask_modkeys = true,
      keypressed_callback = function(_, _, key, _)
        -- Update caps lock indicator on every keypress
        update_caps_lock()

        if key == "Return" then
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
          -- Only append single-codepoint keys; reject named keys
          -- like "Shift_R"
          if utf8_len(key) > 1 then
            return
          end
          password = password .. key
          password_dots.text = string.rep("\xE2\x97\x8F", utf8_len(password))
        end
      end,
    })
  end)

  -- Handle unlock
  awesome.connect_signal("lock::deactivate", function()
    set_visibility_all(false)
    password = ""
    if grab then
      grab:stop()
      grab = nil
    end
  end)

  -- Handle auth failure signal (sole owner of failed_attempts counter)
  awesome.connect_signal("lock::auth_failed", function()
    failed_attempts = failed_attempts + 1
    local plural = failed_attempts == 1 and "attempt" or "attempts"
    set_status(string.format("Authentication failed (%d %s)", failed_attempts, plural), true)
    password = ""
    password_dots.text = ""

    gears.timer.start_new(2, function()
      if awesome.locked then
        if failed_attempts > 0 then
          local p = failed_attempts == 1 and "attempt" or "attempts"
          set_status(string.format("%d failed %s", failed_attempts, p), true)
        else
          set_status("Enter password to unlock", false)
        end
      end
      return false
    end)
  end)
end

return M
