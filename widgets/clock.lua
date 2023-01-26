local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local clock = wrappers.image_widget("/clock.svg", beautiful.fg_normal)
local clock_widget = wrappers.icon_with_text(clock, " " .. os.date "%I:%M")

return clock_widget

