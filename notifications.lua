local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ruled = require("ruled")
local naughty = require("naughty")
local beautiful = require("beautiful")

notification_list = {
  { name = 'Reddit', icon_name = 'reddit.svg', url = 'https://www.reddit.com/' },
  { name = 'StackOverflow', icon_name = 'stackoverflow.svg', url = 'http://github.com/' },
  { name = 'GitHub', icon_name = 'github.svg', url = 'https://stackoverflow.com/' },
}

local popup = awful.popup {
    ontop = true,
    visible = false, -- should be hidden when created
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local function update_popup()
  local n = #notification_list
  naughty.notify({
    title = "Notifications",
    text = tostring(n) .. " notifications",
  })
  local rows = { layout = wibox.layout.fixed.vertical }
  for _, item in ipairs(notification_list) do
      local row = wibox.widget {
          text = item.name,
          widget = wibox.widget.textbox
      }
      table.insert(rows, row)
  end
  local n = #notification_list
  naughty.notify({
    title = "Notifications",
    text = tostring(n) .. " notifications",
  })
  popup:setup(rows)
end
update_popup()



local M = {}

ruled.notification.connect_signal("request::rules", function()
  -- All notifications
  ruled.notification.append_rule({
    rule = {},
    properties = {
      screen = awful.screen.preferred,
      implicit_timeout = 5,
    },
  })

  -- low urgency
  ruled.notification.append_rule({
    rule = { urgency = "low" },
    properties = { bg = beautiful.bg_normal, fg = beautiful.fg_normal },
  })

  -- normal urgency
  ruled.notification.append_rule({
    rule = { urgency = "normal" },
    properties = { bg = beautiful.bg_normal, fg = beautiful.fg_normal },
  })

  -- critical urgency
  ruled.notification.append_rule({
    rule = { urgency = "critical" },
    properties = { bg = beautiful.bg_urgent, fg = beautiful.fg_normal },
  })
end)

local function append_notification(n)
  local notification = {
    name = n.title,
    icon_name = n.app_icon
  }
  gears.table.join(notification_list, notification)
end

naughty.connect_signal("request::display", function(n)
  append_notification(n)
  naughty.layout.box({ notification = n })
  -- append the notification to the global notification_list table
end)

M.toggle_notif_list = function()
  update_popup()

  if popup.visible then
    popup.visible = not popup.visible
  else
    popup:move_next_to(mouse.current_widget_geometry)
  end
end

return M
