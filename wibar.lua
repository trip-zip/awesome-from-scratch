local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")
local dpi = require("beautiful.xresources").apply_dpi

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
        -- Styled systray container with subtle inset appearance
        {
          {
            {
              wibox.widget.systray(),
              margins = dpi(4),
              widget = wibox.container.margin,
            },
            bg = beautiful.bg_focus,
            shape = beautiful.shape_small,
            widget = wibox.container.background,
          },
          left = dpi(8),
          right = dpi(8),
          top = dpi(4),
          bottom = dpi(4),
          widget = wibox.container.margin,
        },
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        {
          {
            s.mylayoutbox,
            forced_height = beautiful.wibar_height * 0.6,
            forced_width = beautiful.wibar_height * 0.6,
            widget = wibox.container.constraint,
          },
          halign = "center",
          valign = "center",
          widget = wibox.container.place,
        },
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.power,
        layout = wibox.layout.fixed.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
  return wibar
end
