local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local wifi = wrappers.image_widget("/wifi.svg", beautiful.bg_normal)
local wifi_widget = wrappers.square_icon(wifi, beautiful.accent, beautiful.accent_hover)

return wifi_widget
