local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local battery = require("widgets.battery")

local profile = {}

-- Display widgets fed by the battery timer; set in create()
local battery_icon, battery_text

local function battery_line(status)
  if not status.percentage then
    return "No battery"
  end

  local text = status.percentage .. "%"
  if status.charging and status.time_to_full then
    text = text .. " · " .. status.time_to_full .. " until full"
  elseif status.time_to_empty then
    text = text .. " · " .. status.time_to_empty .. " remaining"
  else
    text = text .. " · Plugged in"
  end
  return text
end

local function render_battery(status)
  if battery_icon then
    battery_icon.text = battery.level_icon(status.percentage or 0, status.charging)
    battery_text.text = battery_line(status)
  end
end

-- The shared battery module already polls every 10 seconds; this section
-- just renders whatever it broadcasts instead of running its own poll
awesome.connect_signal("battery::update", render_battery)

-- Get greeting based on time of day
local function get_greeting()
  local hour = tonumber(os.date("%H"))
  local user = os.getenv("USER") or "user"

  -- Same hour boundaries as the lockscreen greeting, on purpose
  if hour >= 5 and hour < 12 then
    return "Good morning, " .. user
  elseif hour >= 12 and hour < 18 then
    return "Good afternoon, " .. user
  elseif hour >= 18 and hour < 22 then
    return "Good evening, " .. user
  else
    return "Good night, " .. user
  end
end

--- Create the profile widget
function profile.create()
  -- Time display
  local time_widget = wibox.widget({
    format = "%H:%M",
    font = beautiful.font_size(48, "Bold"),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Date display
  local date_widget = wibox.widget({
    format = "%A, %B %d",
    font = beautiful.font_size(14),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Greeting
  local greeting_widget = wibox.widget({
    text = get_greeting(),
    font = beautiful.font_size(12),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Update greeting periodically
  gears.timer({
    timeout = 60,
    autostart = true,
    call_now = true,
    callback = function()
      greeting_widget.text = get_greeting()
    end,
  })

  -- Battery indicator (updated by the module-level battery timer)
  battery_icon = wibox.widget({
    text = "󰁿",
    font = beautiful.font_size(14),
    widget = wibox.widget.textbox,
  })

  battery_text = wibox.widget({
    text = "…",
    font = beautiful.font_size(11),
    widget = wibox.widget.textbox,
  })
  -- Seed the display now; the broadcast keeps it fresh afterwards
  battery.get_status(render_battery)

  local battery_widget = wibox.widget({
    {
      battery_icon,
      battery_text,
      spacing = 8,
      layout = wibox.layout.fixed.horizontal,
    },
    halign = "center",
    widget = wibox.container.place,
  })

  -- User icon (optional - can use profile picture if available)
  local user_icon = wibox.widget({
    {
      text = "",
      font = beautiful.font_size(36),
      halign = "center",
      valign = "center",
      widget = wibox.widget.textbox,
    },
    fg = beautiful.primary_color or beautiful.fg_normal,
    widget = wibox.container.background,
  })

  return wibox.widget({
    {
      {
        user_icon,
        {
          time_widget,
          date_widget,
          {
            greeting_widget,
            fg = beautiful.fg_normal .. "AA",
            widget = wibox.container.background,
          },
          spacing = 4,
          layout = wibox.layout.fixed.vertical,
        },
        spacing = 16,
        layout = wibox.layout.fixed.vertical,
      },
      halign = "center",
      widget = wibox.container.place,
    },
    {
      {
        battery_widget,
        fg = beautiful.fg_normal .. "CC",
        widget = wibox.container.background,
      },
      top = 12,
      widget = wibox.container.margin,
    },
    {
      {
        orientation = "horizontal",
        forced_height = 1,
        color = beautiful.fg_normal .. "33",
        widget = wibox.widget.separator,
      },
      top = 16,
      widget = wibox.container.margin,
    },
    layout = wibox.layout.fixed.vertical,
  })
end

return profile
