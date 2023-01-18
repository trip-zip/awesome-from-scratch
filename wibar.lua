local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local recolor = gears.color.recolor_image
local theme_path = string.format("%s/.config/awesome/theme", os.getenv("HOME"))

local bar_image_widget = wibox.widget{
  image = recolor(theme_path .. "/table-cells-large-solid.svg", beautiful.fg_normal),
  widget = wibox.widget.imagebox,
}

local square_widget = function(w, color)
  return wibox.widget({
  {
    w,
    margins = beautiful.wibar_height / 8,
    widget = wibox.container.margin,
  },
  bg = color,
  fg = beautiful.fg_normal,
  border_width = dpi(1),
  border_color = beautiful.border_color_marked,
  shape = gears.shape.rectangle,
  widget = wibox.container.background,
})
end

local awful = require("awful")

return function(s)
  local wibar = awful.wibar({
    expand = "none",
    position = "top",
    screen = s,
    widget = {
      {
        square_widget(bar_image_widget, beautiful.border_color_marked),
        square_widget(bar_image_widget, beautiful.border_color_active),
        square_widget(bar_image_widget, beautiful.bg_urgent),
        layout = wibox.layout.align.horizontal,
      },
      square_widget(bar_image_widget, beautiful.soft_green),
      {
        square_widget(bar_image_widget, beautiful.soft_green),
        layout = wibox.layout.align.horizontal,
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
