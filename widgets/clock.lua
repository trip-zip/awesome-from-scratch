local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local notifications = require("notifications")
local utils = require("utils")

local clock = wrappers.image_widget("/clock.svg", beautiful.fg_normal)
local clock_widget = wrappers.icon_with_text(clock)

clock_widget:add_button(awful.button({}, 1, function()
  notifications.toggle_notif_list()
end))



local set_clock = function()
  local time = " " .. os.date("%I:%M")
  local tbox = clock_widget:get_children_by_id("text")[1]
  tbox.text = time
end

gears.timer({
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = function()
    set_clock()
  end,
})

return clock_widget
