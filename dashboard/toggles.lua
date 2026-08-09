local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local notifications = require("notifications")

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

-- Re-read functions collected per toggle, so the dashboard can refresh all
-- toggle states from the system every time it opens.
local refreshers = {}

-- Interpret a check command's output as on/off. Frontier patterns (%f) match
-- whole words only, so "on" inside "disconnected" does not count as enabled.
local function parse_enabled(stdout)
  local out = stdout:lower()
  return (
    out:match("%f[%a]yes%f[%A]")
    or out:match("%f[%a]on%f[%A]")
    or out:match("%f[%a]enabled%f[%A]")
    or out:match("^%s*1%s*$")
  ) ~= nil
end

--- Create a toggle button
-- @tparam string icon The icon character
-- @tparam string label The button label
-- @tparam string key The state key
-- @tparam function on_toggle Callback when toggled (receives new state)
-- @tparam string check_cmd Optional command to read the real state
-- @tparam string signal Optional signal that announces external state changes
local function create_toggle(icon, label, key, on_toggle, check_cmd, signal)
  local active_color = beautiful.primary_color
  local inactive_color = beautiful.bg_focus

  local icon_widget = wibox.widget({
    text = icon,
    font = beautiful.font_size(20),
    halign = "center",
    valign = "center",
    widget = wibox.widget.textbox,
  })

  local label_widget = wibox.widget({
    text = label,
    font = beautiful.font_size(10),
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
    container.bg = toggle_states[key] and beautiful.primary_color_hover or beautiful.bg_minimize
  end)

  container:connect_signal("mouse::leave", function()
    update_visual()
  end)

  -- Read the real state now and again whenever the dashboard refreshes
  if check_cmd then
    local function read_state()
      awful.spawn.easy_async_with_shell(check_cmd, function(stdout)
        toggle_states[key] = parse_enabled(stdout)
        update_visual()
      end)
    end
    read_state()
    table.insert(refreshers, read_state)
  end

  -- Mirror state changes made elsewhere (keybindings, other widgets)
  if signal then
    awesome.connect_signal(signal, function(state)
      toggle_states[key] = state
      update_visual()
    end)
  end

  return container
end

--- Re-read every toggle's state from the system (called on dashboard open)
function toggles.refresh()
  for _, read_state in ipairs(refreshers) do
    read_state()
  end
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

  -- Do Not Disturb toggle: drives the notification module directly and
  -- follows it when DND is toggled from anywhere else
  toggle_states.dnd = notifications.config.dnd_mode
  local dnd_toggle = create_toggle("󰂛", "DND", "dnd", function(state)
    notifications.set_dnd_mode(state)
  end, nil, "notifications::dnd_changed")

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
      font = beautiful.font_size(11, "Bold"),
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
        color = beautiful.fg_normal .. "33",
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
