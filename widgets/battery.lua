local awful = require("awful")
local gears = require("gears")
local recolor = require("gears").color.recolor_image
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local hostname = awesome.hostname

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
  This command always prints out 3 lines.
  state: charging, discharging
  time to [full|empty]: time in hours & minutes
  percentage: 
  
  Again, since I only have 2 icons.  Charging and regular battery.  If it's doing anything but charging, it's regular battery
--]]
  if hostname == "c3po" then
    return
  end
  local cmd =
    [[upower -i $(upower -e | grep 'BAT') | grep -E "state|to full|to empty|percentage" | cut -d ':' -f2 | awk '{$1=$1};1']]
  awful.spawn.easy_async_with_shell(cmd, function(stdout)
    local data = gears.string.split(stdout, "\n")
    local state = data[1]
    local time = data[2]
    local percentage = data[3]
    local tbox = battery_widget:get_children_by_id("text")[1]
    tbox.text = " " .. percentage

    local time_key

    if string.find(state, "discharging") then
      time_key = "Time to empty: "
      battery.image = recolor(beautiful.icon_dir .. "/battery.svg", icon_color)
    else
      battery.image = recolor(beautiful.icon_dir .. "/battery-charging.svg", icon_color)
      time_key = "Time to full: "
    end
    battery_widget.tooltip.text = time_key .. time
  end)
end

gears.timer({
  timeout = 10,
  autostart = true,
  call_now = true,
  callback = update,
})

return battery_widget
