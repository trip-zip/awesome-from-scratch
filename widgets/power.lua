local awful = require("awful")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local exitscreen = require("exitscreen")

local power = wrappers.image_widget("/power.svg", beautiful.bg_normal)
local power_widget = wrappers.square_icon(power, beautiful.primary_color, beautiful.primary_color_hover)

-- Click for the power menu (the exit screen)
power_widget:add_button(awful.button({}, 1, function()
  exitscreen.show()
end))

return power_widget
