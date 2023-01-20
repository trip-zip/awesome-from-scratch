local beautiful = require("beautiful")
local wibox = require("wibox")
local wrappers = require("widgets.wrappers")

local tag = wrappers.image_widget("/battery.svg", beautiful.fg_normal)
local tag_widget = wrappers.square_icon(tag, beautiful.bg_normal)

return wibox.widget({
  tag_widget,
  tag_widget,
  tag_widget,
  widget = wibox.layout.fixed.horizontal
})
