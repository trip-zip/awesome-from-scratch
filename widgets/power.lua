local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local power = wrappers.image_widget("/power.svg", beautiful.bg_normal)
local power_widget = wrappers.square_icon(power, beautiful.primary_color)

return power_widget
