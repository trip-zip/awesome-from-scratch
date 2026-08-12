local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local exitscreen = require("exitscreen")

-- Same construction as the menu button: a real button, so it paints a colored
-- square behind the icon and reacts to the pointer, with its shape taken from
-- the theme rather than hardcoded.
local power_widget = wibox.widget({
  {
    {
      image = beautiful.icon("power.svg", beautiful.bg_normal),
      halign = "center",
      valign = "center",
      widget = wibox.widget.imagebox,
    },
    margins = beautiful.widget_icon_margins,
    widget = wibox.container.margin,
  },
  bg = beautiful.primary_color,
  fg = beautiful.fg_normal,
  shape = beautiful.shape,
  widget = wibox.container.background,
})

power_widget:connect_signal("mouse::enter", function(w)
  w.bg = beautiful.primary_color_hover
end)
power_widget:connect_signal("mouse::leave", function(w)
  w.bg = beautiful.primary_color
end)

-- Click for the power menu (the exit screen)
power_widget:add_button(awful.button({}, 1, function()
  exitscreen.show()
end))

return power_widget
