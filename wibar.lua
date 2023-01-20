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
        widgets.taglist,
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
