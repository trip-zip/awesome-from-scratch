local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local launcher = wrappers.image_widget("/grid.svg", beautiful.bg_normal)
local launcher_widget = wrappers.square_icon(launcher, beautiful.primary_color, beautiful.primary_color_hover)

return launcher_widget
