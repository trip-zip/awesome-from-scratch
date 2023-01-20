local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local launcher = wrappers.image_widget("/grid.svg", beautiful.fg_normal)
local launcher_widget = wrappers.square_icon(launcher, beautiful.primary_color)

return launcher_widget

