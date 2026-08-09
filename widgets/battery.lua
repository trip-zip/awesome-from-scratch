local awful = require("awful")
local gears = require("gears")
local recolor = require("gears").color.recolor_image
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local icon_color = beautiful.fg_normal
local background_color = beautiful.accent
local background_color_hover = beautiful.accent_hover

local battery = wrappers.image_widget("/battery.svg", icon_color)
-- local battery_widget = wrappers.square_icon(battery, background_color, background_color_hover)
local battery_widget = wrappers.icon_with_text(battery)
battery_widget.tooltip = awful.tooltip({
  objects = { battery_widget },
})

local function update()
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

  I only have 2 icons. Charging, and regular battery. If it's doing anything but
  charging, it's regular battery.
--]]
  local cmd = [[
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

  awful.spawn.easy_async_with_shell(cmd, function(stdout)
    stdout = stdout or ""
    local percentage = stdout:match("percentage:%s*(%d+)%%")
    local state = stdout:match("state:%s*([%w%-]+)") or "unknown"
    local time_to_empty = stdout:match("time to empty:%s*([^\n]-)%s*\n")
    local time_to_full = stdout:match("time to full:%s*([^\n]-)%s*\n")

    -- No percentage means no battery: a desktop, a VM, or a nested test instance.
    -- Hide the widget rather than parking a permanent "N/A" in the bar.
    if not percentage then
      battery_widget.visible = false
      return
    end
    battery_widget.visible = true

    local tbox = battery_widget:get_children_by_id("text")[1]
    tbox.text = " " .. percentage .. "%"

    local charging = state:lower():find("charging") and not state:lower():find("discharging")
    battery.image = recolor(beautiful.icon_dir .. (charging and "/battery-charging.svg" or "/battery.svg"), icon_color)

    if charging and time_to_full then
      battery_widget.tooltip.text = "Time to full: " .. time_to_full
    elseif time_to_empty then
      battery_widget.tooltip.text = "Time to empty: " .. time_to_empty
    else
      battery_widget.tooltip.text = ("Battery: %s%% (%s)"):format(percentage, state)
    end
  end)
end

gears.timer({
  timeout = 10,
  autostart = true,
  call_now = true,
  callback = update,
})

return battery_widget
