local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local recolor = gears.color.recolor_image
local icon_dir = string.format("%s/.config/awesome/icons", os.getenv("HOME"))

local image_widget = function(image, color)
  return wibox.widget({
    image = recolor(icon_dir .. image, color),
    widget = wibox.widget.imagebox,
    halign = "center",
    valign = "center",
  })
end

local vertical_separator = wibox.widget{
  bg = beautiful.bg_normal,
  forced_width = beautiful.wibar_height * 0.2,
  widget = wibox.container.background
}

local square_icon = function(w, color)
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

local launcher = image_widget("/grid.svg", beautiful.bg_normal)
local launcher_widget = square_icon(launcher, beautiful.primary_color)

local volume = image_widget("/volume-x.svg", beautiful.fg_normal)
local volume_widget = square_icon(volume, beautiful.bg_normal)
-- local volume_widget = square_icon(volume, beautiful.active)

local wifi = image_widget("/wifi.svg", beautiful.fg_normal)
local wifi_widget = square_icon(wifi, beautiful.bg_normal)
-- local wifi_widget = square_icon(wifi, beautiful.accent)

local battery = image_widget("/battery.svg", beautiful.fg_normal)
local battery_widget = square_icon(battery, beautiful.bg_normal)
-- local battery_widget = square_icon(battery, beautiful.highlight)

local power = image_widget("/power.svg", beautiful.bg_normal)
local power_widget = square_icon(power, beautiful.primary_color)
-- local power_widget = square_icon(power, beautiful.primary_color)

local empty = square_icon(launcher, beautiful.bg_normal)

return function(s)
  local wibar = awful.wibar({
    expand = "none",
    position = "top",
    screen = s,
    widget = {
      {
        launcher_widget,
        vertical_separator,
        layout = wibox.layout.fixed.horizontal,
      },
      empty,
      {
        volume_widget,
        vertical_separator,
        wifi_widget,
        vertical_separator,
        battery_widget,
        vertical_separator,
        power_widget,
        layout = wibox.layout.fixed.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
  return wibar
end

-- -- Each screen has its own tag table.
-- awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
--
-- -- Create a promptbox for each screen
-- s.mypromptbox = awful.widget.prompt()
--
-- -- Create an imagebox widget which will contain an icon indicating which layout we're using.
-- -- We need one layoutbox per screen.
-- s.mylayoutbox = awful.widget.layoutbox({
--   screen = s,
--   buttons = {
--     awful.button({}, 1, function()
--       awful.layout.inc(1)
--     end),
--     awful.button({}, 3, function()
--       awful.layout.inc(-1)
--     end),
--     awful.button({}, 4, function()
--       awful.layout.inc(-1)
--     end),
--     awful.button({}, 5, function()
--       awful.layout.inc(1)
--     end),
--   },
-- })
--
-- -- Create a taglist widget
-- s.mytaglist = awful.widget.taglist({
--   screen = s,
--   filter = awful.widget.taglist.filter.all,
--   buttons = {
--     awful.button({}, 1, function(t)
--       t:view_only()
--     end),
--     awful.button({ modkey }, 1, function(t)
--       if client.focus then
--         client.focus:move_to_tag(t)
--       end
--     end),
--     awful.button({}, 3, awful.tag.viewtoggle),
--     awful.button({ modkey }, 3, function(t)
--       if client.focus then
--         client.focus:toggle_tag(t)
--       end
--     end),
--     awful.button({}, 4, function(t)
--       awful.tag.viewprev(t.screen)
--     end),
--     awful.button({}, 5, function(t)
--       awful.tag.viewnext(t.screen)
--     end),
--   },
-- })
--
-- -- @TASKLIST_BUTTON@
-- -- Create a tasklist widget
-- s.mytasklist = awful.widget.tasklist({
--   screen = s,
--   filter = awful.widget.tasklist.filter.currenttags,
--   buttons = {
--     awful.button({}, 1, function(c)
--       c:activate({ context = "tasklist", action = "toggle_minimization" })
--     end),
--     awful.button({}, 3, function()
--       awful.menu.client_list({ theme = { width = 250 } })
--     end),
--     awful.button({}, 4, function()
--       awful.client.focus.byidx(-1)
--     end),
--     awful.button({}, 5, function()
--       awful.client.focus.byidx(1)
--     end),
--   },
-- })
-- {{{ Wibar

-- Create a textclock widget
-- mytextclock = wibox.widget.textclock()
