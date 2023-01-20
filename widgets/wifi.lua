local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local wifi = wrappers.image_widget("/wifi.svg", beautiful.fg_normal)
local wifi_widget = wrappers.square_icon(wifi, beautiful.bg_normal)

return wifi_widget


