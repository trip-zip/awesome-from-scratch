local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local battery = wrappers.image_widget("/battery.svg", beautiful.bg_normal)
local battery_widget = wrappers.square_icon(battery, beautiful.active)
-- local battery = wrappers.image_widget("/battery.svg", beautiful.fg_normal)
-- local battery_widget = wrappers.square_icon(battery, beautiful.bg_normal)

return battery_widget
