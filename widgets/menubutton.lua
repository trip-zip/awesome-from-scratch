local awful = require("awful")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local mainmenu = require("widgets.mainmenu")

local menubutton = wrappers.image_widget("/grid.svg", beautiful.bg_normal)
local menubutton_widget = wrappers.square_icon(menubutton, beautiful.primary_color, beautiful.primary_color_hover)
menubutton_widget:add_button(awful.button({}, 1, function()
  mainmenu.toggle()
end))

return menubutton_widget
