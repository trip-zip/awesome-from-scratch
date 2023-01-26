local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local recolor = gears.color.recolor_image
local utils = require("utils")

local M = {}

M.image_widget = function(image, color, hover_color)
  local widget = wibox.widget({
    image = recolor(beautiful.icon_dir .. image, color),
    widget = wibox.widget.imagebox,
    halign = "center",
    valign = "center",
  })
  widget:connect_signal("mouse::enter", function(c)
    c.image = recolor(beautiful.icon_dir .. image, hover_color or color)
  end)
  widget:connect_signal("mouse::leave", function(c)
    c.image = recolor(beautiful.icon_dir .. image, color)
  end)
  return widget
end

M.square_icon = function(w, color, hover_color)
  local widget = wibox.widget({
    {
      w,
      margins = beautiful.wibar_height / 4,
      widget = wibox.container.margin,
    },
    bg = color,
    -- border_width = 1,
    -- border_color = beautiful.border_focus,
    fg = beautiful.fg_normal,
    shape = gears.shape.rectangle,
    widget = wibox.container.background,
  })
  widget:connect_signal("mouse::enter", function(c)
    c.bg = hover_color or color
  end)
  widget:connect_signal("mouse::leave", function(c)
    c.bg = color
  end)
  return widget
end

M.vertical_separator = function(width)
  return wibox.widget({
    bg = beautiful.bg_normal,
    forced_width = width,
    widget = wibox.container.background,
  })
end

M.icon_with_text = function(w, text)
  return wibox.widget({
    {
      w,
      margins = {
        top = beautiful.wibar_height / 4,
        bottom = beautiful.wibar_height / 4,
      },
      widget = wibox.container.margin,
    },
    {
      id = "text",
      text = text,
      widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
  })
end

return M
