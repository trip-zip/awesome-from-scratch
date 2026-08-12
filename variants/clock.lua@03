local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

-- Both mutable parts carry an id, so building the widget and updating it later
-- go through the same door: get_children_by_id.
local clock_widget = wibox.widget({
  {
    {
      id = "icon",
      image = beautiful.icon("clock.svg"),
      halign = "center",
      valign = "center",
      widget = wibox.widget.imagebox,
    },
    margins = beautiful.widget_icon_margins,
    widget = wibox.container.margin,
  },
  {
    id = "text",
    widget = wibox.widget.textbox,
  },
  spacing = beautiful.widget_icon_spacing,
  layout = wibox.layout.fixed.horizontal,
})

local function set_clock()
  clock_widget:get_children_by_id("text")[1].text = os.date("%I:%M")
end

gears.timer({
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = set_clock,
})

return clock_widget
