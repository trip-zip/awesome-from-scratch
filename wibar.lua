local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")

return function(s)
  local wibar = awful.wibar({
    expand = "none",
    position = "top",
    screen = s,
    widget = {
      {
        widgets.launcher,
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.taglist(s),
        layout = wibox.layout.fixed.horizontal,
      },
      {
        nil,
        widgets.clock,
        nil,
        expand = "none",
        layout = wibox.layout.align.horizontal,
      },
      {
        widgets.volume,
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.wifi,
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.battery,
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.power,
        layout = wibox.layout.fixed.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
  return wibar
end
