local awful = require("awful")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local mainmenu = require("widgets.mainmenu")

local launcher = wrappers.image_widget("/grid.svg", beautiful.bg_normal)
local launcher_widget = wrappers.square_icon(launcher, beautiful.primary_color, beautiful.primary_color_hover)
launcher_widget:add_button(awful.button({}, 1, function()
  mainmenu:toggle()
end))

return launcher_widget
