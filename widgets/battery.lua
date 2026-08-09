local awful = require("awful")
local gears = require("gears")
local recolor = require("gears").color.recolor_image
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

-- The one battery implementation in this config. The wibar shows M.widget;
-- the dashboard profile and the lockscreen call M.get_status() and share the
-- same thresholds through M.level_color() / M.level_icon(), so all three
-- always agree about what the battery is doing.
local M = {}

local icon_color = beautiful.fg_normal

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

--- Theme color for a charge level: fine, getting low, act now
function M.level_color(percent)
  if percent > 50 then
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
local battery_icon = wrappers.image_widget("/battery.svg", icon_color)
M.widget = wrappers.icon_with_text(battery_icon)
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

    local tbox = M.widget:get_children_by_id("text")[1]
    tbox.text = " " .. status.percentage .. "%"

    battery_icon.image =
      recolor(beautiful.icon_dir .. (status.charging and "/battery-charging.svg" or "/battery.svg"), icon_color)

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
