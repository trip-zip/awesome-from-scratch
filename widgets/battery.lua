local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local battery = wrappers.image_widget("/battery.svg", beautiful.bg_normal)
local battery_widget = wrappers.square_icon(battery, beautiful.active, beautiful.active_hover)

return battery_widget
