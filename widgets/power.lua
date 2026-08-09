local awful = require("awful")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local power = wrappers.image_widget("/power.svg", beautiful.bg_normal)
local power_widget = wrappers.square_icon(power, beautiful.primary_color, beautiful.primary_color_hover)

-- Click to lock screen (somewm built-in lockscreen)
power_widget:add_button(awful.button({}, 1, function()
  awesome.lock()
end))

return power_widget
