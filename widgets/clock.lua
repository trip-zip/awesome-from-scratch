local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local notifications = require("notifications")

-- Icon, time, and an unread-notification badge in one row. Every mutable part
-- carries an id, so building the widget and updating it later go through the
-- same door: get_children_by_id.
local clock_widget = wibox.widget({
  {
    {
      id = "icon",
      image = beautiful.icon("clock.svg"),
      halign = "center",
      valign = "center",
      widget = wibox.widget.imagebox,
    },
    margins = beautiful.widget_icon_margins,
    widget = wibox.container.margin,
  },
  {
    id = "text",
    widget = wibox.widget.textbox,
  },
  {
    {
      id = "badge",
      text = "",
      align = "center",
      valign = "center",
      font = beautiful.font_size(7, "Bold"),
      widget = wibox.widget.textbox,
    },
    id = "badge_container",
    bg = beautiful.bg_urgent,
    fg = beautiful.fg_urgent,
    shape = gears.shape.circle,
    forced_width = dpi(12),
    forced_height = dpi(12),
    visible = false,
    widget = wibox.container.background,
  },
  spacing = beautiful.widget_icon_spacing,
  layout = wibox.layout.fixed.horizontal,
})

clock_widget:add_button(awful.button({}, 1, function()
  notifications.toggle_notification_center()
end))

local function set_clock()
  clock_widget:get_children_by_id("text")[1].text = os.date("%I:%M")
end

local function set_badge()
  local badge_container = clock_widget:get_children_by_id("badge_container")[1]
  local badge_text = clock_widget:get_children_by_id("badge")[1]
  local count = notifications.unread_count or 0

  if count > 0 then
    badge_text.text = tostring(math.min(count, 99))
    badge_container.visible = true
  else
    badge_container.visible = false
  end
end

gears.timer({
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = set_clock,
})

-- Update the badge when the unread count changes, rather than re-running the
-- clock formatting for something that has nothing to do with the time.
set_badge()
awesome.connect_signal("notification::unread_count", set_badge)

return clock_widget
