local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local notifications = require("notifications")
local utils = require("utils")

local clock = wrappers.image_widget("/clock.svg", beautiful.fg_normal)
local clock_widget_base = wrappers.icon_with_text(clock)

-- Create a widget with badge for unread notifications
local clock_widget = wibox.widget({
  {
    clock_widget_base,
    {
      {
        id = "badge",
        text = "",
        align = "center",
        valign = "center",
        font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " Bold 7",
        widget = wibox.widget.textbox,
      },
      bg = beautiful.bg_urgent or "#ff0000",
      fg = "#ffffff",
      shape = gears.shape.circle,
      forced_width = 12,
      forced_height = 12,
      visible = false,
      widget = wibox.container.background,
      id = "badge_container",
    },
    layout = wibox.layout.fixed.horizontal,
    spacing = 2,
  },
  widget = wibox.container.constraint,
  strategy = "max",
})

clock_widget:add_button(awful.button({}, 1, function()
  local widget_geometry = mouse.current_widget_geometry
  notifications.toggle_notif_list(widget_geometry)
end))

local set_clock = function()
  local time = " " .. os.date("%I:%M")
  local tbox = clock_widget_base:get_children_by_id("text")[1]
  tbox.text = time
  
  -- Update unread badge
  local badge_container = clock_widget:get_children_by_id("badge_container")[1]
  local badge_text = clock_widget:get_children_by_id("badge")[1]
  
  if badge_container and badge_text and notifications.unread_count and notifications.unread_count > 0 then
    badge_text.text = tostring(math.min(notifications.unread_count, 99))
    badge_container.visible = true
  elseif badge_container then
    badge_container.visible = false
  end
end

gears.timer({
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = function()
    set_clock()
  end,
})

-- Update badge when unread count changes
awesome.connect_signal("notification::unread_count", function(count)
  set_clock()
end)

return clock_widget
