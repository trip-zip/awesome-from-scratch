local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local toggles = {}

-- Toggle state storage
local toggle_states = {
  wifi = true,
  bluetooth = false,
  dnd = false,
  nightlight = false,
  airplane = false,
  mic = true,
}

--- Create a toggle button
-- @tparam string icon The icon character
-- @tparam string label The button label
-- @tparam string key The state key
-- @tparam function on_toggle Callback when toggled (receives new state)
-- @tparam function check_cmd Optional command to check initial state
local function create_toggle(icon, label, key, on_toggle, check_cmd)
  local active_color = beautiful.primary_color or "#d65d0e"
  local inactive_color = beautiful.bg_focus or "#3c3836"

  local icon_widget = wibox.widget({
    text = icon,
    font = "JetBrainsMono Nerd Font 20",
    halign = "center",
    valign = "center",
    widget = wibox.widget.textbox,
  })

  local label_widget = wibox.widget({
    text = label,
    font = "JetBrainsMono Nerd Font 10",
    halign = "center",
    widget = wibox.widget.textbox,
  })

  local container = wibox.widget({
    {
      {
        icon_widget,
        label_widget,
        spacing = 4,
        layout = wibox.layout.fixed.vertical,
      },
      margins = 10,
      widget = wibox.container.margin,
    },
    bg = toggle_states[key] and active_color or inactive_color,
    fg = toggle_states[key] and beautiful.bg_normal or beautiful.fg_normal,
    shape = beautiful.shape_small,
    forced_width = 90,
    forced_height = 76,
    widget = wibox.container.background,
  })

  -- Update visual state
  local function update_visual()
    if toggle_states[key] then
      container.bg = active_color
      container.fg = beautiful.bg_normal
    else
      container.bg = inactive_color
      container.fg = beautiful.fg_normal
    end
  end

  -- Toggle on click
  container:add_button(awful.button({}, 1, function()
    toggle_states[key] = not toggle_states[key]
    update_visual()
    if on_toggle then
      on_toggle(toggle_states[key])
    end
  end))

  -- Hover effect
  container:connect_signal("mouse::enter", function()
    container.bg = toggle_states[key] and (beautiful.primary_color_hover or "#fe8019")
      or (beautiful.bg_minimize or "#928374")
  end)

  container:connect_signal("mouse::leave", function()
    update_visual()
  end)

  -- Check initial state if command provided
  if check_cmd then
    awful.spawn.easy_async_with_shell(check_cmd, function(stdout)
      local enabled = stdout:match("yes") or stdout:match("on") or stdout:match("enabled") or stdout:match("1")
      toggle_states[key] = enabled ~= nil
      update_visual()
    end)
  end

  return container
end

--- Create the toggles section
function toggles.create()
  -- WiFi toggle
  local wifi_toggle = create_toggle("󰤨", "WiFi", "wifi", function(state)
    if state then
      awful.spawn("nmcli radio wifi on")
    else
      awful.spawn("nmcli radio wifi off")
    end
  end, "nmcli radio wifi 2>/dev/null || echo off")

  -- Bluetooth toggle
  local bluetooth_toggle = create_toggle("󰂯", "BT", "bluetooth", function(state)
    if state then
      awful.spawn("bluetoothctl power on")
    else
      awful.spawn("bluetoothctl power off")
    end
  end, "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off")

  -- Do Not Disturb toggle
  local dnd_toggle = create_toggle("󰂛", "DND", "dnd", function(state)
    awesome.emit_signal("notification::dnd", state)
  end, nil)

  -- Night Light toggle
  local nightlight_toggle = create_toggle("󰖔", "Night", "nightlight", function(state)
    if state then
      awful.spawn("gammastep -O 4500")
    else
      awful.spawn("pkill gammastep")
    end
  end, "pgrep gammastep >/dev/null && echo on || echo off")

  -- Airplane mode toggle
  local airplane_toggle = create_toggle("󰀝", "Airplane", "airplane", function(state)
    if state then
      awful.spawn("nmcli radio all off")
    else
      awful.spawn("nmcli radio all on")
    end
  end, nil)

  -- Microphone toggle
  local mic_toggle = create_toggle("󰍬", "Mic", "mic", function(state)
    if state then
      awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0")
    else
      awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1")
    end
  end, [[wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED && echo off || echo on]])

  return wibox.widget({
    {
      text = "Quick Settings",
      font = "JetBrainsMono Nerd Font Bold 11",
      widget = wibox.widget.textbox,
    },
    {
      {
        {
          wifi_toggle,
          bluetooth_toggle,
          dnd_toggle,
          spacing = 12,
          layout = wibox.layout.fixed.horizontal,
        },
        {
          nightlight_toggle,
          airplane_toggle,
          mic_toggle,
          spacing = 12,
          layout = wibox.layout.fixed.horizontal,
        },
        spacing = 12,
        layout = wibox.layout.fixed.vertical,
      },
      halign = "center",
      widget = wibox.container.place,
    },
    {
      {
        orientation = "horizontal",
        forced_height = 1,
        color = (beautiful.fg_normal or "#ebdbb2") .. "33",
        widget = wibox.widget.separator,
      },
      top = 16,
      widget = wibox.container.margin,
    },
    spacing = 8,
    layout = wibox.layout.fixed.vertical,
  })
end

return toggles
