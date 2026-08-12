local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

-- The one battery implementation in this config. The wibar shows M.widget;
-- the dashboard profile and the lockscreen call M.get_status() and share the
-- same thresholds through M.level_color() / M.level_icon(), so all three
-- always agree about what the battery is doing.
local M = {}

--[[
  Read the battery by KEY, not by line number.

  The obvious version of this pipes upower through `cut -d: -f2` and then indexes the
  result: line 1 is the state, line 2 the time estimate, line 3 the percentage. That
  works right up until it doesn't, and it fails in two ways that are easy to miss:

  1. `upower -e | grep BAT` matches every battery upower knows about, which on a laptop
     with a wireless mouse is two devices, not one.
  2. A fully charged battery has no "time to empty" and no "time to full" line, so the
     output is two lines instead of three, everything shifts up one, and the percentage
     silently becomes whatever used to be the time.

  So: pick exactly one device, keep the labels, and match on them.
--]]
local status_cmd = [[
  if command -v upower >/dev/null 2>&1 && upower -e | grep -q 'battery_BAT'; then
    upower -i "$(upower -e | grep 'battery_BAT' | head -n1)"
  else
    # Fallback to sysfs. BAT0 on some machines, BAT1 on others.
    for bat in /sys/class/power_supply/BAT*; do
      [ -r "$bat/capacity" ] || continue
      echo "    state:               $(cat "$bat/status")"
      echo "    percentage:          $(cat "$bat/capacity")%"
      break
    done
  fi
]]

--- Read the battery asynchronously. The callback receives a table:
--- { percentage = number|nil, state, charging, time_to_empty, time_to_full }.
--- percentage is nil when there is no battery (desktop, VM, nested test).
function M.get_status(cb)
  awful.spawn.easy_async_with_shell(status_cmd, function(stdout)
    stdout = stdout or ""
    local percentage = tonumber(stdout:match("percentage:%s*(%d+)%%"))
    local state = stdout:match("state:%s*([%w%-]+)") or "unknown"
    local charging = state:lower():find("charging") ~= nil and state:lower():find("discharging") == nil

    cb({
      percentage = percentage,
      state = state,
      charging = charging,
      time_to_empty = stdout:match("time to empty:%s*([^\n]-)%s*\n"),
      time_to_full = stdout:match("time to full:%s*([^\n]-)%s*\n"),
    })
  end)
end

--- Theme color for a charge level: fine, getting low, act now.
--- Callers may pass a nil percentage (no battery), so treat that as "fine"
--- rather than throwing on the comparison.
function M.level_color(percent)
  if not percent or percent > 50 then
    return beautiful.active_hover
  elseif percent > 20 then
    return beautiful.accent_hover
  else
    return beautiful.urgent_hover
  end
end

--- Nerd-font glyph for a charge level
function M.level_icon(percent, charging)
  if charging then
    return "󰂄"
  elseif percent >= 90 then
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

-- The wibar widget: recolored SVG icon + percentage, tooltip with the time
-- estimate. I only have 2 icons - charging, and regular battery. If it's
-- doing anything but charging, it's regular battery.
--
-- Both mutable parts carry an id, so building the widget and updating it later
-- go through the same door: get_children_by_id.
M.widget = wibox.widget({
  {
    {
      id = "icon",
      image = beautiful.icon("battery.svg"),
      halign = "center",
      valign = "center",
      widget = wibox.widget.imagebox,
    },
    margins = beautiful.widget_icon_margins,
    widget = wibox.container.margin,
  },
  {
    id = "text",
    widget = wibox.widget.textbox,
  },
  spacing = beautiful.widget_icon_spacing,
  layout = wibox.layout.fixed.horizontal,
})

M.widget.tooltip = awful.tooltip({
  objects = { M.widget },
})

local function update()
  M.get_status(function(status)
    -- Broadcast for every other battery display (the dashboard profile
    -- listens), so the whole config shares this one 10-second poll
    awesome.emit_signal("battery::update", status)

    -- No percentage means no battery: hide the widget rather than parking a
    -- permanent "N/A" in the bar.
    if not status.percentage then
      M.widget.visible = false
      return
    end
    M.widget.visible = true

    M.widget:get_children_by_id("text")[1].text = status.percentage .. "%"
    M.widget:get_children_by_id("icon")[1].image =
      beautiful.icon(status.charging and "battery-charging.svg" or "battery.svg")

    if status.charging and status.time_to_full then
      M.widget.tooltip.text = "Time to full: " .. status.time_to_full
    elseif status.time_to_empty then
      M.widget.tooltip.text = "Time to empty: " .. status.time_to_empty
    else
      M.widget.tooltip.text = ("Battery: %s%% (%s)"):format(status.percentage, status.state)
    end
  end)
end

gears.timer({
  timeout = 10,
  autostart = true,
  call_now = true,
  callback = update,
})

return M
