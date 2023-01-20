local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local volume = wrappers.image_widget("/volume-x.svg", beautiful.fg_normal)
local volume_widget = wrappers.square_icon(volume, beautiful.bg_normal)

return volume_widget
