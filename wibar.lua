local awful = require("awful")
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
        widgets.wrappers.vertical_separator,
        widgets.taglist(s),
        layout = wibox.layout.fixed.horizontal,
      },
      nil,
      {
        widgets.volume,
        widgets.wrappers.vertical_separator,
        widgets.wifi,
        widgets.wrappers.vertical_separator,
        widgets.battery,
        widgets.wrappers.vertical_separator,
        widgets.power,
        layout = wibox.layout.fixed.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
  return wibar
end
