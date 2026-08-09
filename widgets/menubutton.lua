local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local mainmenu = require("widgets.mainmenu")

-- Unlike the status readouts, this is a real button: it paints a colored
-- square behind the icon and reacts to the pointer. The shape comes from the
-- theme, so flipping theme.shape_style rounds this off with everything else.
local menubutton_widget = wibox.widget({
  {
    {
      image = beautiful.icon("grid.svg", beautiful.bg_normal),
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

menubutton_widget:connect_signal("mouse::enter", function(w)
  w.bg = beautiful.primary_color_hover
end)
menubutton_widget:connect_signal("mouse::leave", function(w)
  w.bg = beautiful.primary_color
end)

menubutton_widget:add_button(awful.button({}, 1, function()
  mainmenu.toggle()
end))

return menubutton_widget
