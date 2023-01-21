local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local battery = wrappers.image_widget("/battery.svg", beautiful.bg_normal)
local battery_widget = wrappers.square_icon(battery, beautiful.active, beautiful.active_hover)
battery_widget.tooltip = awful.tooltip({
  objects = { battery_widget },
})

local function update()
--[[
  This command always prints out 3 lines.
  status: charging, discharging
  time to [full|empty]: time in hours & minutes
  percentage: 
  
  Again, since I only have 2 icons.  Charging and regular battery.  If it's doing anything but charging, it's regular battery
  Just print the output in the tooltip
--]]
local cmd = [[upower -i $(upower -e | grep 'BAT') | grep -E "state|to full|to empty|percentage" | awk '{ gsub(/[ ]+/," "); print }']]
  awful.spawn.easy_async_with_shell(cmd, function(stdout)
    battery_widget.tooltip.text = stdout
    local data = gears.string.split(stdout, "\n")
    if string.find(data[1], "discharging") then
      battery.image = beautiful.icon_dir .. "/battery.svg"
    else
      battery.image = beautiful.icon_dir .. "/battery-charging.svg"
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
