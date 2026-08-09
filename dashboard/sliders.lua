local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local sliders = {}

-- Slider configuration
local slider_config = {
  bar_height = 6,
  handle_width = 16,
  forced_height = 24,
}

-- Re-read functions collected per slider, so the dashboard can sync every
-- slider with the real system value each time it opens.
local refreshers = {}

--- Create a labeled slider widget
-- @tparam string icon The icon character
-- @tparam string color The accent color
-- @tparam string get_cmd Command to read the current system value
-- @tparam function set_cmd Function that takes a value and returns the set command
-- @tparam string signal Optional signal meaning "the value changed elsewhere, re-read it"
local function create_slider(icon, color, get_cmd, set_cmd, signal)
  local slider = wibox.widget({
    bar_shape = gears.shape.rounded_bar,
    bar_height = slider_config.bar_height,
    bar_color = beautiful.bg_focus,
    bar_active_color = color,
    handle_shape = gears.shape.circle,
    handle_width = slider_config.handle_width,
    handle_color = color,
    handle_border_width = 0,
    value = 50,
    minimum = 0,
    maximum = 100,
    forced_height = slider_config.forced_height,
    widget = wibox.widget.slider,
  })

  local icon_widget = wibox.widget({
    text = icon,
    font = beautiful.font_size(18),
    halign = "center",
    valign = "center",
    forced_width = 28,
    widget = wibox.widget.textbox,
  })

  local value_widget = wibox.widget({
    text = "50%",
    font = beautiful.font_size(11),
    halign = "right",
    forced_width = 40,
    widget = wibox.widget.textbox,
  })

  -- property::value fires for programmatic assignments too. Without this
  -- guard, reading the system value and assigning it to the slider would
  -- immediately write that same value back to the system.
  local setting_programmatically = false

  local function set_value(value)
    setting_programmatically = true
    slider.value = math.min(100, math.max(0, value))
    setting_programmatically = false
  end

  -- Update value display when slider changes; only user drags hit the system
  slider:connect_signal("property::value", function()
    local value = math.floor(slider.value)
    value_widget.text = value .. "%"

    if set_cmd and not setting_programmatically then
      awful.spawn.with_shell(set_cmd(value))
    end
  end)

  -- Sync the slider to the real system value
  local function read_system_value()
    if not get_cmd then
      return
    end
    awful.spawn.easy_async_with_shell(get_cmd, function(stdout)
      set_value(tonumber(stdout:match("(%d+)")) or 50)
    end)
  end

  read_system_value()
  table.insert(refreshers, read_system_value)

  -- External changes (e.g. the volume keybindings) announce themselves with a
  -- bare signal; the payload is fetched fresh from the system.
  if signal then
    awesome.connect_signal(signal, read_system_value)
  end

  return wibox.widget({
    {
      icon_widget,
      fg = color,
      widget = wibox.container.background,
    },
    {
      slider,
      left = 12,
      right = 12,
      widget = wibox.container.margin,
    },
    value_widget,
    layout = wibox.layout.align.horizontal,
  })
end

--- Create the sliders section
function sliders.create()
  -- Volume slider
  local volume_slider = create_slider(
    "󰕾",
    beautiful.primary_color,
    [[wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo 50]],
    function(value)
      return string.format("wpctl set-volume @DEFAULT_AUDIO_SINK@ %d%%", value)
    end,
    "volume::update"
  )

  -- Brightness slider. No signal: nothing else in the config changes
  -- brightness, and the dashboard re-reads it on every open anyway.
  local brightness_slider = create_slider(
    "󰃟",
    beautiful.accent,
    [[brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%' || echo 50]],
    function(value)
      return string.format("brightnessctl set %d%%", value)
    end,
    nil
  )

  return wibox.widget({
    {
      text = "Controls",
      font = beautiful.font_size(11, "Bold"),
      widget = wibox.widget.textbox,
    },
    {
      {
        volume_slider,
        brightness_slider,
        spacing = 12,
        layout = wibox.layout.fixed.vertical,
      },
      top = 8,
      widget = wibox.container.margin,
    },
    {
      {
        orientation = "horizontal",
        forced_height = 1,
        color = beautiful.fg_normal .. "33",
        widget = wibox.widget.separator,
      },
      top = 16,
      widget = wibox.container.margin,
    },
    layout = wibox.layout.fixed.vertical,
  })
end

--- Re-sync every slider with the system (called on dashboard open)
function sliders.refresh()
  for _, read_system_value in ipairs(refreshers) do
    read_system_value()
  end
end

return sliders
