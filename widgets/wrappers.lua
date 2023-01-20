local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local recolor = gears.color.recolor_image
local icon_dir = string.format("%s/.config/awesome/icons", os.getenv("HOME"))

local M = {}

M.image_widget = function(image, color)
  return wibox.widget({
    image = recolor(icon_dir .. image, color),
    widget = wibox.widget.imagebox,
    halign = "center",
    valign = "center",
  })
end

M.square_icon = function(w, color)
  return wibox.widget({
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
end

M.vertical_separator = wibox.widget{
  bg = beautiful.bg_normal,
  forced_width = beautiful.wibar_height * 0.2,
  widget = wibox.container.background
}

return M
